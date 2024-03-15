# Motoko Event Hub 

This repository contains the implementation of the Event Hub in [Motoko](https://github.com/dfinity/motoko) programming language for [Internet Computer](https://internetcomputer.org/). 

The Event Hub is responsible for managing events, subscribers, and emitting events to subscribers. 

It is possible to track events on the Ethereum blockchain using Ethereum RPC methods.

## Features

**Event management**: The Event Hub can emit events to all subscribed subscribers and return the result.
**Subscription management**: The Event Hub can manage subscribers, allowing them to subscribe and unsubscribe.
**Ethereum RPC methods**: The Event Hub can interact with Ethereum RPC methods.

## Usage

```candid "Type definitions" +=
type Value = variant { 
    Blob : blob; 
    Bool : bool;
    Text : text; 
    Nat : nat;
    Nat8 : nat8;
    Int : int;
    Array : vec Value; 
    Map : vec record { text; Value }; 
};
    
    type EventName = variant {
        #EthEvent;
        #CreateEvent;
        #BurnEvent;
        #CollectionCreatedEvent;
        #CollectionUpdatedEvent;
        #CollectionDeletedEvent;
        #AddToCollectionEvent;
        #RemoveFromCollectionEvent;
        #InstantReputationUpdateEvent;
        #AwaitingReputationUpdateEvent;
        #NewRegistrationEvent;
        #FeedbackSubmissionEvent;
        #Unknown;
    };

```

### Subscribing
Subscribers can subscribe to the Event Hub using the subscribe function. The function takes a Subscriber as input and returns a boolean indicating the success of the operation.

```candid "Type definitions" +=
    type Subscriber = {
        callback : Principal; // subscriber's canister_id
        filter : EventFilter;
    };
    type EventFilter = {
        eventType : ?EventName;
        fieldFilters : [EventField];
    };
    type EventField = {
        name : Text;
        value : Blob;
    };
```

```candid "Methods" +=
subscribe : (Subscriber) -> (Bool)
```

### Unsubscribing
Subscribers can unsubscribe from the Hub using the unsubscribe function. The function takes a Principal as input.

```candid "Methods" +=
unsubscribe: (Principal) -> ();
```

### Emitting Events
Events can be emitted to all subscribed subscribers using the emitEvent function. The function takes an Event as input and returns a Result indicating the success or failure of the operation.

```candid "Type definitions" +=
    type CanisterId = principal;

    type EmitEventResult = variant {
        #SubscribersNotified : SubscribersNotifiedResult;
        #Answers : AnswersResult;
    };

    type SubscribersNotifiedResult = {
        successful : [Success];
        errors : [SendError];
    };

    type Success = {
        canisterId : CanisterId;
        result : (nat, nat);
    };

    type SendError = {
        canisterId : CanisterId;
        error : ErrorType;
    };

    type ErrorType = variant {
        #CommunicationError;
        #ProcessingError;
        #Timeout;
        #CustomError : text;
    };

    type Answer = {
        canisterId : CanisterId;
        result : [(text, Value)];
    };

    type AnswersResult = {
        successful : [Answer];
        errors : [SendError];
    };
```

```candid "Methods" +=
emitEventGeneral: (Event) ->  EmitEventResult;
```

### Event Types Samples
```candid "Type definitions" +=
    public type NewsEvent = actor {
        news : (Event) -> async ();
    };

    public type InstantReputationUpdateEvent = actor {
        getCategories : () -> async [(Category, Text)];
        getMintingAccount : () -> async Principal;
        eventHandler : (ReputationChangeRequest) -> async Result<Nat, Text>;
    };

    public type EthEvent = actor {
        handleEthEvent : (EthEvent) -> async Result<[Key, Value], Text>;
        emitEthEvent : (EthEvent) -> async Result<[Key, Value], Text>;
    };
```

### Ethereum RPC methods
The Event Hub provides functions for interacting with Ethereum RPC methods. These functions include callEthgetLogs, callEthgetBlockByNumber, and callEthsendRawTransaction.

### Dependencies
This project depends on [evm_rpc canister](https://github.com/internet-computer-protocol/evm-rpc-canister).

### Contributing
Contributions are welcome. Please submit a pull request or open an issue to discuss your ideas.

### License
This project is licensed under the terms of the MIT license.



#### Start the local replica
dfx start --background

#### Locally deploy the `evm_rpc` canister
dfx deps pull
dfx deps init evm_rpc --argument '(record { nodesInSubnet = 28 })'
dfx deps deploy

### Deploy
dfx deploy
