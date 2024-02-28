/**
 * @desc This file contains the implementation of the `Hub` actor class.
 * The `Hub` class is responsible for managing events, subscribers, and emitting events to subscribers.
 * It also provides functions for interacting with Ethereum RPC methods.
 */

import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Cycles "mo:base/ExperimentalCycles";
import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Option "mo:base/Option";
import Order "mo:base/Order";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";

import Sender "./EventSender";
import E "./EventTypes";
import Types "./Types";
import List "utils/List";
import Logger "utils/Logger";
import Canister "utils/matcher/Canister";
import Utils "utils/Utils";

/**
 * @desc The `Hub` actor class manages events, subscribers, and emits events to subscribers.
 */
actor class Hub() = Self {

    //eth types
    type RpcSource = Types.RpcSource;
    type RpcConfig = Types.RpcConfig;
    type GetLogsArgs = Types.GetLogsArgs;
    // type MultiGetLogsResult = Types.MultiGetLogsResult;

    type EventField = E.EventField;

    type Event = E.Event;

    type EventFilter = E.EventFilter;

    type Subscriber = E.Subscriber;

    type EventName = E.EventName;

    type CanisterId = Text;

    type DocId = Nat;

    // Logger

    stable var state : Logger.State<Text> = Logger.new<Text>(0, null);
    let logger = Logger.Logger<Text>(state);
    let prefix = Utils.timestampToDate() # " ";

    let default_principal : Principal = Principal.fromText("aaaaa-aa");
    let rep_canister_id = "aoxye-tiaaa-aaaal-adgnq-cai";
    let default_doctoken_canister_id = "h5x3q-hyaaa-aaaal-adg6q-cai";
    let default_receiver_canister_id = default_doctoken_canister_id;
    let default_reputation_fee = 550_000_000;
    let default_subscription_fee = 500_000_000_000;

    // subscriber : <canisterId , filter>

    var eventHub = {
        var events : [E.Event] = [];
        subscribers : HashMap.HashMap<Principal, Subscriber> = HashMap.HashMap<Principal, Subscriber>(10, Principal.equal, Principal.hash);
    };

    public func viewLogs(end : Nat) : async [Text] {
        let view = logger.view(0, end);
        let result = Buffer.Buffer<Text>(1);
        for (message in view.messages.vals()) {
            result.add(message);
        };
        Buffer.toArray(result);
    };

    public func clearAllLogs() : async Bool {
        logger.clear();
        true;
    };

    public shared func subscribe(subscriber : Subscriber) : async Bool {
        // let amount = Cycles.available();
        // if (amount < default_subscription_fee) {
        //     return false;
        // };
        // ignore Cycles.accept(default_subscription_fee);
        eventHub.subscribers.put(subscriber.callback, subscriber);
        true;
    };

    public func unsubscribe(principal : Principal) : async () {
        eventHub.subscribers.delete(principal);
    };

    public func getSubscriberFilters() : async [EventFilter] {
        let result = Buffer.Buffer<EventFilter>(0);
        for (filter in eventHub.subscribers.vals()) {
            result.add(filter.filter);
        };
        Buffer.toArray(result);
    };

    // This function emits an event to all subscribed subscribers and returns the result.
    // It takes an event as input and checks if the caller has enough cycles to emit the event.
    // If the caller has enough cycles, it adds the event to the eventHub and sends the event to all matching subscribers.
    // The function returns the result of sending the event to the subscribers.

    public shared ({ caller }) func emitEvent(event : E.Event) : async E.Result<[(Nat, Nat)], Text> {
        // let amount = Cycles.available();
        // if (amount < default_reputation_fee * 1_000 + 200_000_000_000) {
        //     return #Err("Not enough cycles to emit event");
        // };
        // ignore Cycles.accept(amount);
        eventHub.events := Utils.pushIntoArray(event, eventHub.events);
        let buffer = Buffer.Buffer<(Nat, Nat)>(0);
        for (subscriber in eventHub.subscribers.vals()) {
            // logger.append([prefix # "emitEvent: check subscriber " # Principal.toText(subscriber.callback) # " with filter " # subscriber.filter.fieldFilters[0].name]);

            if (isEventMatchFilter(event, subscriber.filter)) {
                logger.append([prefix # "emitEvent: event matched"]);

                var canister_doctoken = Principal.toText(caller);
                if (Principal.fromText("2vxsx-fae") == caller) canister_doctoken := default_doctoken_canister_id;
                let response = await sendEvent(event, canister_doctoken, subscriber.callback);
                switch (response) {
                    case (#Ok(array)) { buffer.add(array[0]) };
                    case (#Err(err)) { return #Err(err) };
                };
            };
        };

        return #Ok(Buffer.toArray<(Nat, Nat)>(buffer));
    };

    /*
    * General emitEvent
    * Description: Emits a general event to all subscribed callbacks and handles the responses.
    * Parameters:
    * - event: The event to be emitted.
    * Returns: An EmitEventResult indicating the arrays of success or failure of the event emission.
    */
    public shared ({ caller }) func emitEventGeneral(event : E.Event) : async E.EmitEventResult {
        // Add event to the event log
        eventHub.events := Utils.pushIntoArray(event, eventHub.events);

        let successes = Buffer.Buffer<E.Success>(0); // Buffer for successful sends
        let errors = Buffer.Buffer<E.SendError>(0); // Buffer for errors

        // Iterate over subscribers
        for (subscriber in eventHub.subscribers.vals()) {
            if (isEventMatchFilter(event, subscriber.filter)) {
                // Prepare canister_doctoken based on the caller
                var caller_id = Principal.toText(caller);
                if (Principal.fromText("2vxsx-fae") == caller) {
                    caller_id := default_doctoken_canister_id;
                };

                // Send event to subscriber and handle response
                let response = await sendEvent(event, caller_id, subscriber.callback);
                switch (response) {
                    case (#Ok(result)) {
                        // Add to the success buffer
                        successes.add({
                            canisterId = subscriber.callback;
                            result = result[0];
                        });
                    };
                    case (#Err(message)) {
                        // Add to the error buffer
                        errors.add({
                            canisterId = subscriber.callback;
                            error = #CustomError(message);
                        });
                    };
                };
            };
        };

        // Return results based on the responseType

        let notifiedResults = {
            successful = Buffer.toArray(successes);
            errors = Buffer.toArray(errors);
        };
        // let responseType = switch (event.reputation_change.reviewer) {
        //     case (null) { #SubscribersNotified };
        //     case (?_) { #Answers };
        // };
        return #SubscribersNotified(notifiedResults);

    };

    /*
   * Ethereum RPC methods
   */

    func callEthgetLogs(source : RpcSource, config : ?RpcConfig, getLogArgs : GetLogsArgs) : async Types.MultiGetLogsResult {
        let response = await Sender.eth_getLogs(source, config, getLogArgs);
        return response;
    };

    func callEthgetBlockByNumber(source : RpcSource, config : ?RpcConfig, blockTag : Types.BlockTag) : async Types.MultiGetBlockByNumberResult {
        let response = await Sender.eth_getBlockByNumber(source, config, blockTag);
        return response;
    };

    func callEthsendRawTransaction(source : RpcSource, config : ?RpcConfig, rawTx : Text) : async Types.MultiSendRawTransactionResult {
        let response = await Sender.eth_sendRawTransaction(source, config, rawTx);
        return response;
    };

    func eventNameToText(eventName : EventName) : Text {
        switch (eventName) {
            case (#NewCanisterEvent) { "NewCanisterEvent" };
            case (#EthEvent) { "EthEvent" };
            case (#CreateEvent) { "CreateEvent" };
            case (#BurnEvent) { "BurnEvent" };
            case (#CollectionCreatedEvent) { "CollectionCreatedEvent" };
            case (#CollectionUpdatedEvent) { "CollectionUpdatedEvent" };
            case (#CollectionDeletedEvent) { "CollectionDeletedEvent" };
            case (#AddToCollectionEvent) { "AddToCollectionEvent" };
            case (#RemoveFromCollectionEvent) { "RemoveFromCollectionEvent" };
            case (#InstantReputationUpdateEvent) {
                "InstantReputationUpdateEvent";
            };
            case (#AwaitingReputationUpdateEvent) {
                "AwaitingReputationUpdateEvent";
            };
            case (#FeedbackSubmissionEvent) { "FeedbackSubmissionEvent" };
            case (#NewRegistrationEvent) { "NewRegistrationEvent" };
            case (#Unknown) { "Unknown" };
        };
    };

    func isEventMatchFilter(event : E.Event, filter : EventFilter) : Bool {
        // logger.append([prefix # " isEventMatchFilter: Checking subsriber's event type", eventNameToText(Option.get<E.EventName>(filter.eventType, #Unknown))]);
        // logger.append([prefix # " with event type: ", eventNameToText(event.eventType)]);
        switch (filter.eventType) {
            case (null) {
                logger.append([prefix # "isEventMatchFilter: Event type is null"]);
            };
            case (?t) if (t != event.eventType) {
                logger.append([prefix # "isEventMatchFilter: Event type does not match: " # eventNameToText(event.eventType) # " and " # eventNameToText(t)]);
                return false;
            };
        };
        // logger.append([prefix # " isEventMatchFilter: event topic 1: name = " # event.topics[0].name # " , value = " # Nat8.toText(Blob.toArray(event.topics[0].value)[0])]);
        for (field in filter.fieldFilters.vals()) {
            logger.append([prefix # "isEventMatchFilter: Checking field", field.name, Nat8.toText(Blob.toArray(field.value)[0])]);
            let found = Array.find<EventField>(
                event.topics,
                func(topic : EventField) : Bool {
                    topic.name == field.name and topic.value == field.value
                },
            );
            if (found == null) {
                logger.append([prefix # "isEventMatchFilter: Field not found", field.name]);
                return false;
            };
        };
        logger.append([prefix # "isEventMatchFilter: Event matched"]);
        return true;
    };

    /*
    * Sends an event to a subscriber canister and handles the response.
    * Returns a result containing a list of event IDs and corresponding balances,
    * or an error text message if the update failed.
    */
    func sendEvent(event : E.Event, caller_canister_id : Text, canisterId : Principal) : async E.Result<[(Nat, Nat)], Text> {

        // logger.append([prefix # "Starting method sendEvent"]);
        let subscriber_canister_id = Principal.toText(canisterId);
        switch (event.eventType) {
            case (#InstantReputationUpdateEvent(_)) {
                logger.append([prefix # "sendEvent: case #InstantReputationUpdateEvent, start eventHandler"]);
                let canister : E.InstantReputationUpdateEvent = actor (subscriber_canister_id);
                // logger.append([prefix # "sendEvent: canister created"]);
                let args : E.ReputationChangeRequest = event.reputation_change;
                let rep_value = Nat.toText(Option.get<Nat>(args.value, 0));
                logger.append([
                    prefix # "sendEvent: args created, user=" # Principal.toText(args.user) # " token Id = " # Nat.toText(args.source.1)
                    # " caller_canister_id = " # args.source.0 # " value = " # rep_value # " comment " # Option.get<Text>(args.comment, "null")
                ]);

                // Call eventHandler method from subscriber canister
                // Cycles.add(default_reputation_fee);
                let response : E.Result<Nat, Text> = await canister.eventHandler(args);
                logger.append([prefix # "sendEvent: eventHandler method has been executed."]);
                switch (response) {
                    case (#Ok(balance)) return #Ok([(
                        args.source.1,
                        balance,
                    )]);
                    case (#Err(msg)) {
                        return #Err("Update failed: " # msg);
                    };
                };
            };
            case (#EthEvent(_)) {
                // let canister : E.EthEvent = actor (subscriber_canister_id);
                // let response = await canister.emitEthEvent(event);
                //TODO: remove temp Demo code
                let address = ["0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"];
                let topic1 = "0xe1fffcc4923d04b559f4d29a8bfc6cda04eb5b0d3c460751c2402c5c5cc9109c";
                let topic2 = "0x0000000000000000000000003fc91a3afd70395cd496c647d5a6cc9d4b2b7fad";
                let fromBlock = 19188367;
                let toBlock = 19188368;
                let topics = [topic1, topic2];
                let getLogArgs : Types.GetLogsArgs = {
                    addresses = address;
                    fromBlock = ? #Number(fromBlock);
                    toBlock = ? #Number(toBlock);
                    topics = ?[topics];
                };
                let source : Types.RpcSource = (#EthMainnet(?[#Cloudflare]));
                let responseTemp : Types.MultiGetLogsResult = await callEthgetLogs(source, null, getLogArgs);
                var result = #Ok([]);
                switch (responseTemp) {
                    case (#Consistent(#Ok(res))) {
                        result := #Ok([]);
                    };
                    case (_) {
                        return #Err("Error in eth_getLogs");
                    };
                };
                switch (result) {
                    case (#Ok(res)) {
                        // #Ok(tx, balance)
                        return #Ok([(8, 0)]);

                    };
                    case (#Err(err)) {
                        return #Err("Error in emitEthEvent: " # err);
                    };
                };
            };
            case (#NewCanisterEvent(_)) {
                let canister : E.NewCanisterEvent = actor (subscriber_canister_id);
                let response = await canister.newCanister(event);
                switch (response) {
                    case (#SubscribersNotified(result)) {
                        // TODO change return type to EmitEventResult,  expression of type   [Success] cannot produce expected type   [(Nat, Nat)]
                        //return #Ok(result.successful);
                        return #Ok(Array.map<E.Success, (Nat, Nat)>(result.successful, func(x : E.Success) : (Nat, Nat) { (0, 0) }));
                    };
                    case (#Answers(result)) {
                        return #Ok(Array.map<E.Answer, (Nat, Nat)>(result.successful, func(x : E.Answer) : (Nat, Nat) { (0, 0) }));
                    };
                };
            };
            // TODO Add other types here
            case _ {
                return #Err("Unknown Event Type");
            };
        };
    };

    public shared ({ caller }) func getAllSubscribers() : async [Subscriber] {
        Iter.toArray(eventHub.subscribers.vals());
    };

    public func getSubscribers(filter : EventFilter) : async [Subscriber] {
        let subscribers = Iter.toArray(eventHub.subscribers.vals());

        let filteredSubscribers = Array.filter<Subscriber>(
            subscribers,
            func(subscriber : Subscriber) : Bool {
                return compareEventFilter(subscriber.filter, filter);
            },
        );

        return filteredSubscribers;
    };

    private func compareEventFilter(filter1 : EventFilter, filter2 : EventFilter) : Bool {
        switch (filter1.eventType, filter2.eventType) {
            case (null, null) {};
            case (null, _) {};
            case (_, null) {};
            case (?type1, ?type2) if (type1 != type2) return false;
        };

        let sortedFields1 = Array.sort<EventField>(
            filter1.fieldFilters,
            func(x : EventField, y : EventField) : Order.Order {
                Text.compare(x.name, y.name);
            },
        );
        let sortedFields2 = Array.sort<EventField>(
            filter2.fieldFilters,
            func(x : EventField, y : EventField) : Order.Order {
                Text.compare(x.name, y.name);
            },
        );

        return Array.equal<EventField>(
            sortedFields1,
            sortedFields2,
            func(x : EventField, y : EventField) : Bool {
                x.name == y.name and x.value == y.value
            },
        );
    };

    /*
    * Upgrade canister methods
    */
    stable var eventState : [E.Event] = [];
    stable var eventSubscribers : [Subscriber] = [];
    stable var userCanisterDoc : [(Principal, [(CanisterId, Nat)])] = [];

    system func preupgrade() {
        eventState := eventHub.events;
        eventSubscribers := Iter.toArray(eventHub.subscribers.vals());
    };

    system func postupgrade() {
        eventHub.events := eventState;
        eventState := [];
        for (subscriber in eventSubscribers.vals()) {
            eventHub.subscribers.put(subscriber.callback, subscriber);
        };
        eventSubscribers := [];
    };
};
