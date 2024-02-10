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

actor class Hub() = Self {
    // Type aliases for readability
    type RpcSource = Types.RpcSource;
    type RpcConfig = Types.RpcConfig;
    type GetLogsArgs = Types.GetLogsArgs;
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

    // Default values
    let default_principal : Principal = Principal.fromText("aaaaa-aa");
    let rep_canister_id = "aoxye-tiaaa-aaaal-adgnq-cai";
    let default_doctoken_canister_id = "h5x3q-hyaaa-aaaal-adg6q-cai";
    let default_receiver_canister_id = default_doctoken_canister_id;
    let default_reputation_fee = 550_000_000;
    let default_subscription_fee = 500_000_000_000;

    // Event hub
    var eventHub = {
        var events : [E.Event] = [];
        subscribers : HashMap.HashMap<Principal, Subscriber> = HashMap.HashMap<Principal, Subscriber>(10, Principal.equal, Principal.hash);
    };

    // Logs viewing and management
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

    // Subscription management
    public shared func subscribe(subscriber : Subscriber) : async Bool {
        eventHub.subscribers.put(subscriber.callback, subscriber);
        true;
    };

    public func unsubscribe(principal : Principal) : async () {
        eventHub.subscribers.delete(principal);
    };

    // Event emission
    public shared ({ caller }) func emitEvent(event : E.Event) : async E.Result<[(Nat, Nat)], Text> {
        eventHub.events := Utils.pushIntoArray(event, eventHub.events);
        let buffer = Buffer.Buffer<(Nat, Nat)>(0);
        for (subscriber in eventHub.subscribers.vals()) {
            if (isEventMatchFilter(event, subscriber.filter)) {
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

    // General event emission
    public shared ({ caller }) func emitEventGeneral(event : E.Event) : async E.EmitEventResult {
        eventHub.events := Utils.pushIntoArray(event, eventHub.events);
        let successes = Buffer.Buffer<E.Success>(0); // Buffer for successful sends
        let errors = Buffer.Buffer<E.SendError>(0); // Buffer for errors

        for (subscriber in eventHub.subscribers.vals()) {
            if (isEventMatchFilter(event, subscriber.filter)) {
                var caller_id = Principal.toText(caller);
                if (Principal.fromText("2vxsx-fae") == caller) {
                    caller_id := default_doctoken_canister_id;
                };
                let response = await sendEvent(event, caller_id, subscriber.callback);
                switch (response) {
                    case (#Ok(result)) {
                        successes.add({
                            canisterId = subscriber.callback;
                            result = result[0];
                        });
                    };
                    case (#Err(message)) {
                        errors.add({
                            canisterId = subscriber.callback;
                            error = #CustomError(message);
                        });
                    };
                };
            };
        };

        let notifiedResults = {
            successful = Buffer.toArray(successes);
            errors = Buffer.toArray(errors);
        };
        return #SubscribersNotified(notifiedResults);
    };

    // Ethereum RPC methods
    public func callEthgetLogs(source : RpcSource, config : ?RpcConfig, getLogArgs : GetLogsArgs) : async Types.MultiGetLogsResult {
        let response = await Sender.eth_getLogs(source, config, getLogArgs);
        return response;
    };

    public func callEthgetBlockByNumber(source : RpcSource, config : ?RpcConfig, blockTag : Types.BlockTag) : async Types.MultiGetBlockByNumberResult {
        let response = await Sender.eth_getBlockByNumber(source, config, blockTag);
        return response;
    };

    public func callEthsendRawTransaction(source : RpcSource, config : ?RpcConfig, rawTx : Text) : async Types.MultiSendRawTransactionResult {
        let response = await Sender.eth_sendRawTransaction(source, config, rawTx);
        return response;
    };

    // Helper functions
    private func isEventMatchFilter(event : Event, filter : EventFilter) : Bool {
        switch (filter.eventType) {
            case (null) {
                // true for null filter
                //logger.append([prefix # "isEventMatchFilter: Event type is null"]);
                return true;
            };
            case (?t) if (t != event.eventType) {
                // logger.append([prefix # "isEventMatchFilter: Event type does not match: " # eventNameToText(event.eventType) # " and " # eventNameToText(t)]);
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

    private func isFieldInEvent(field : EventField, event : Event) : Bool {
        for (eventField in event.topics.vals()) {
            if (field.name == eventField.name & (field.value == eventField.value)) {
                return true;
            };
        };
        return false;
    };

    private func sendEvent(event : Event, canister_doctoken : Text, canister_id : Principal) : async E.Result<[(Nat, Nat)], Text> {
        let subscriber_canister_id = Principal.toText(canisterId);
        switch (event.eventType) {
            case (#InstantReputationUpdateEvent(_)) {
                logger.append([prefix # "sendEvent: case #InstantReputationUpdateEvent, start updateDocHistory"]);
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
                let response : Result<Nat, Text> = await canister.eventHandler(args);
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
                //TODO: Add the logic to handle EthEvent
                let canister : E.EthEvent = actor (subscriber_canister_id);
                let response = await canister.emitEthEvent(event);
                switch (response) {
                    case (#Ok(res)) {
                        // #Ok(tx, balance)
                        return #Ok([(res, 0)]);

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
                        return #Ok(result.successful);
                    };
                };
            };

            // case (#AwaitingReputationUpdateEvent(_)) {
            //     let canister : E.AwaitingReputationUpdateEvent = actor (subscriber_canister_id);
            //     let response = await canister.updateReputation(event);
            // };
            // TODO Add other types here
            case _ {
                return #Err("Unknown Event Type");
            };
        };
    };

    // Querying events
    public func getEvents() : async [E.Event] {
        eventHub.events;
    };

    // Querying subscribers
    public func getSubscribers() : async [E.Subscriber] {
        let subscribers : E.Subscriber = Array.init<Subscriber>(eventHub.subscribers.size(), { callback = default_principal; filter = { eventType = null; fieldFilters = [] } });
        var i = 0;
        for (subscriber in eventHub.subscribers.vals()) {
            subscribers[i] := subscriber;
            i := i + 1;
        };
        subscribers;
    };
    /*
    * Upgrade canister methods
    */
    stable var eventState : [E.Event] = [];
    stable var eventSubscribers : [Subscriber] = [];

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
