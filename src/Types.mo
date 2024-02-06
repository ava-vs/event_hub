import Blob "mo:base/Blob";
import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Result "mo:base/Result";

import E "./EventTypes";

module {

    public type EventFilter = {
        eventType : ?E.EventName;
        fieldFilters : [E.EventField];
    };

    public type RemoteCallEndpoint = {
        canisterId : Principal.Principal;
        methodName : Text;
    };

    public type EncodedEventBatch = {
        content : Blob;
        eventsCount : Nat;
        timestamp : Int;
    };

    public type Subscriber = {
        callback : Principal; // subscriber's canister_id
        filter : EventFilter;
    };

    public type ApiError = {
        #Unauthorized;
        #InvalidTokenId;
        #ZeroAddress;
        #NoNFT;
        #Other;
    };

    public type Result<S, E> = {
        #Ok : S;
        #Err : E;
    };

    // Reputation part

    public type Branch = Nat8;

    public type DocHistory = {
        docId : DocId;
        timestamp : Int;
        changedBy : Principal;
        value : Nat8;
        comment : Text;
    };

    public type CommonError = {
        #InsufficientFunds : { balance : Tokens };
        #BadFee : { expected_fee : Tokens };
        #TemporarilyUnavailable;
        #GenericError : { error_code : Nat; message : Text };
        #NotFound : { message : Text; docId : DocId };
    };

    public type Tokens = Nat;
    public type DocId = Nat;
};
