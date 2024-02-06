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

import E "./EventTypes";
import Types "./Types";
import List "utils/List";
import Logger "utils/Logger";
import Utils "utils/Utils";
import Canister "utils/matcher/Canister";

actor class Hub() = Self {
    type EventField = E.EventField;

    type Event = E.Event;

    type EventFilter = Types.EventFilter;

    type RemoteCallEndpoint = Types.RemoteCallEndpoint;

    type EncodedEventBatch = Types.EncodedEventBatch;

    type Subscriber = Types.Subscriber;

    type EventName = E.EventName;

    type CanisterId = Text;

    type DocId = Nat;

    // Logger

    stable var state : Logger.State<Text> = Logger.new<Text>(0, null);
    let logger = Logger.Logger<Text>(state);
    let prefix = Utils.timestampToDate() # " ";

    // For further batch handling
    var batchMakingDurationNano : Int = 1_000_000_000;
    var batchMaxSizeBytes : Nat = 500_000;

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
    let userCanisterDocMap = HashMap.HashMap<Principal, [(CanisterId, DocId)]>(10, Principal.equal, Principal.hash);

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

    public func getCategories() : async [(E.Category, Text)] {
        let rep_canister : E.InstantReputationUpdateEvent = actor (rep_canister_id);
        let tags = await rep_canister.getCategories();
        tags;
    };

    public shared func subscribe(subscriber : Subscriber) : async Bool {
        let amount = Cycles.available();
        if (amount < default_subscription_fee) {
            return false;
        };
        ignore Cycles.accept(default_subscription_fee);
        eventHub.subscribers.put(subscriber.callback, subscriber);
        true;
    };

    public func unsubscribe(principal : Principal) : async () {
        eventHub.subscribers.delete(principal);
    };

    public shared ({ caller }) func emitEvent(event : E.Event) : async Types.Result<[(Nat, Nat)], Text> {
        let amount = Cycles.available();
        if (amount < default_reputation_fee * 1_000 + 200_000_000_000) {
            return #Err("Not enough cycles to emit event");
        };
        ignore Cycles.accept(amount);

        // logger.append([prefix # "Starting method emitEvent"]);
        eventHub.events := Utils.pushIntoArray(event, eventHub.events);
        updateUserCanisterDocMap(event);
        let buffer = Buffer.Buffer<(Nat, Nat)>(0);
        for (subscriber in eventHub.subscribers.vals()) {
            // logger.append([prefix # "emitEvent: check subscriber " # Principal.toText(subscriber.callback) # " with filter " # subscriber.filter.fieldFilters[0].name]);

            if (isEventMatchFilter(event, subscriber.filter)) {
                logger.append([prefix # "emitEvent: event matched"]);

                var canister_doctoken = Principal.toText(caller);
                if (Principal.fromText("2vxsx-fae") == caller) canister_doctoken := default_doctoken_canister_id;
                let response = await sendEvent(event.reputation_change.reviewer, event, canister_doctoken, subscriber.callback);
                switch (response) {
                    case (#Ok(array)) { buffer.add(array[0]) };
                    case (#Err(err)) { return #Err(err) };
                };
            };
        };

        return #Ok(Buffer.toArray<(Nat, Nat)>(buffer));
    };

    public func getUserDocuments(principal : Principal) : async [(CanisterId, DocId)] {
        switch (userCanisterDocMap.get(principal)) {
            case (?array) {
                return array;
            };
            case null { [] };
        };
    };

    func updateUserCanisterDocMap(event : E.Event) {
        let existing = userCanisterDocMap.get(event.reputation_change.user);
        switch (existing) {
            case (?array) {
                var newArray = Utils.pushIntoArray(event.reputation_change.source, array);
                userCanisterDocMap.put(event.reputation_change.user, newArray);
            };
            case null {
                userCanisterDocMap.put(event.reputation_change.user, [event.reputation_change.source]);
            };
        };
    };

    func eventNameToText(eventName : EventName) : Text {
        switch (eventName) {
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

        // logger.append([prefix # "Starting method isEventMatchFilter"]);

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
        // logger.append([prefix # " isEventMatchFilter: Event type matched"]);
        // logger.append([prefix # " isEventMatchFilter: Checking subsriber's field filters"]);
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

    func sendEvent(reviwer : ?Principal, event : E.Event, caller_doctoken_canister_id : Text, canisterId : Principal) : async Types.Result<[(Nat, Nat)], Text> {

        // logger.append([prefix # "Starting method sendEvent"]);
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
                    # " caller_doctoken_canister_id = " # args.source.0 # " value = " # rep_value # " comment " # Option.get<Text>(args.comment, "null")
                ]);

                // Call eventHandler method from subscriber canister
                Cycles.add(default_reputation_fee);
                let response = await canister.eventHandler(args);
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

    public func getAllSubscribers() : async [Subscriber] {
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

    stable var eventState : [E.Event] = [];
    stable var eventSubscribers : [Subscriber] = [];
    stable var userCanisterDoc : [(Principal, [(CanisterId, Nat)])] = [];

    system func preupgrade() {
        eventState := eventHub.events;
        eventSubscribers := Iter.toArray(eventHub.subscribers.vals());
        userCanisterDoc := Iter.toArray(userCanisterDocMap.entries());
    };

    system func postupgrade() {
        eventHub.events := eventState;
        eventState := [];
        for (subscriber in eventSubscribers.vals()) {
            eventHub.subscribers.put(subscriber.callback, subscriber);
        };
        eventSubscribers := [];
        for (user in userCanisterDoc.vals()) {
            userCanisterDocMap.put(user.0, user.1);
        };
        userCanisterDoc := [];
    };
};
