import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Text "mo:base/Text";

import E "./EventTypes";

module {
    public type HubInterface = actor {
        subscribeWithFilter : shared (subscriber : Principal, filter : E.EventFilter) -> async Bool;
        unsubscribeAll : shared (subscriber : Principal) -> async ();
        createEvent : shared (eventType : Text, topics : [Text], details : ?Text, reputationChange : ?E.ReputationChangeRequest, senderHash : ?Text) -> async E.Event;
        emitEvent : shared (event : E.Event) -> async E.Result<[(Nat, Nat)], Text>;

        // issueEvent : shared (eventFilter : E.EventFilter, publisher : Principal, details : ?Text, start_at : Int, expire_at : ?Int, metadata : [(Text, E.Value)]) -> ();
        // add more methods here

        // Add methods for GenericEvent
        createGenericEvent : shared (
            eventType : E.EventName,
            filter : E.EventField,
            details : ?Text,
            start_at : Nat64,
            expiresAt : ?Nat64,
            metadata : [(Text, E.Value)]
        ) -> (); //async E.GenericEvent;

        //emitGenericEvent : shared (event : E.GenericEvent) -> (); //async E.Result<[(Nat, Nat)], Text>;

    };
};
