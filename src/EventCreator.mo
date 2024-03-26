import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
// import Cycles "mo:base/ExperimentalCycles";
// import HashMap "mo:base/HashMap";
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
// import Utils "utils/Utils";

module {
    /**
    * Event Constructors
    */

    public func createEvent(eventType : E.EventName, topics : [E.EventField], details : ?Text, reputationChange : ?E.ReputationChangeRequest, senderHash : ?Text) : E.Event {
        let reputationChangeRequest : E.ReputationChangeRequest = switch (reputationChange) {
            case (null) {
                {
                    user = default_principal;
                    reviewer = null;
                    value = null;
                    category = "";
                    timestamp = 0;
                    source = ("", 0);
                    comment = null;
                    metadata = null;
                };
            };
            case (?request) request;
        };

        return {
            eventType = eventType;
            topics = topics;
            details = details;
            reputation_change = reputationChangeRequest;
            sender_hash = senderHash;
        };
    };

    // InstantReputationUpdateEvent constructor
    public func createInstantReputationUpdateEvent(reputationChange : E.ReputationChangeRequest) : E.Event {
        return {
            eventType = #InstantReputationUpdateEvent;
            topics = [];
            details = null;
            reputation_change = reputationChange;
            sender_hash = null;
        };
    };

    // EthEvent constructor

    public func createEthereumEvent(topics : [E.EventField], details : ?Text, ethDetails : E.EthereumEventDetails) : E.EthEvent {
        return {
            eventType = #EthEvent;
            topics = topics;
            details = details;
            ethDetails = ethDetails;
            sender_hash = null;
        };
    };

    public func createEthEvent(topics : [E.EventField], details : ?Text) : E.Event {
        return {
            eventType = #EthEvent;
            topics = topics;
            details = details;
            reputation_change = {
                user = default_principal;
                reviewer = null;
                value = null;
                category = "";
                timestamp = 0;
                source = ("", 0);
                comment = null;
                metadata = null;
            };
            sender_hash = null;
        };
    };

    // Send some events to the subscribers
    public shared ({ caller }) func emitEvents(events : [E.Event]) : async [E.EmitEventResult] {
        let results = Buffer.Buffer<E.EmitEventResult>(0);

        for (event in events.vals()) {
            let result = await emitEventGeneral(event);
            results.add(result);
        };

        return Buffer.toArray(results);
    };
    

};
