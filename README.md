# Motoko Event Hub 

This repository contains the implementation of the **Event Hub** in [Motoko](https://github.com/dfinity/motoko) programming language for [Internet Computer](https://internetcomputer.org/). 

## Summary:

In the IC ecosystem, with its diverse set of decentralized applications (canisters), there's a critical need for an efficient mechanism to manage and disseminate events to multiple stakeholders. 

**Event Hub** is a node for managing events, subscribers, and sending events to subscribers.

This canister provides methods for subscribing to events, unsubscribing from events, viewing and clearing event logs, and generating and sending events to subscribers.

**Event Hub** also provides interoperability with Ethereum RPC methods and uses flexible event types and custom filters.
 
## Overview:
![Event_Hub](https://github.com/ava-vs/event_hub/assets/30374212/e29abbbf-2d5f-4bdf-a981-4403f8aedbac)

### Functions:
- Subscriber Management: Functions for subscribing (subscribe) and unsubscribing (unsubscribe) actors to events are implemented, as well as functions for getting a list of all subscribers (getAllSubscribers) and subscribers with certain filters (getSubscribers).
- Generating and sending events: Includes functions to generate events (emitEvent, emitEventGeneral) and send them to subscribers. Events are filtered according to the set subscriber filters.
- Ethereum Interaction: Functions are provided for calling Ethereum RPC methods (callEthgetLogs, callEthgetBlockByNumber, callEthsendRawTransaction).
- Canister Update: The state of the hub is stable and is not lost when the canister is updated.
- Logging: The code provides a logging system to track events and operations within an actor.

**Event Hub** is a complete solution for event management in the context of Internet Computer, supporting both intra-network and Ethereum blockchain interactions.

### Use case examples

#### Case 1 ("A new NFT Canister", it can be part of the standard)
Wallets subscribe to the canister event of the ICRC-7 standard in the hub, and when a new canister starts issuing NFTs of that standard and sends an event about it to the hub, all subscribers receive a new NFT source canister ID and can search for NFTs there by address or number.

![New_NFT_Canister](https://github.com/ava-vs/event_hub/assets/30374212/146fe23c-9fa9-40bc-9e23-8c9234ce7bd8)


#### Case 2 ("Ethereum Event")
The canister subscribes to an event in the Ethereum network. The hub periodically checks for the occurrence of this event using the evm_rpc call and notifies the subscriber when it occurs.


![Eth_handle](https://github.com/ava-vs/event_hub/assets/30374212/844b2035-3db6-4714-a078-a43bc2319922)

#### Case 3 ("Verified Event with Reputation", already implemented by aVa Reputation) 
Online school issues a digital certificate as NFT for graduatee and create special event. 

aVa Reputation canister gets this event notification with token and some reputation points add to certificate. 

User received certificate with reputation.Online school issues digital certificate as NFT for graduate and creates special event. 

aVa reputation canister gets this event notification with token and some reputation points added to certificate. 

User gets certificate with reputation.

![reputation_event](https://github.com/ava-vs/event_hub/assets/30374212/9c99c316-3a66-44b9-91f4-0700210920a4)


## Project Roadmap 

- Develop full version of **Event Hub** and get it into production
 
- Gather and implement the community's wishes for the events they want
 
- Create a decentralised autonomous organisation (DAO) and hand over the management of **Event Hub** to it.


## Features

**Event management**: The **Event Hub** can emit events to all subscribed subscribers and return the result.

**Subscription management**: The **Event Hub** can manage subscribers, allowing them to subscribe and unsubscribe.

**Ethereum RPC methods**: The **Event Hub** can interact with Ethereum RPC methods via [evm_rpc](https://github.com/internet-computer-protocol/evm-rpc-canister) canister.

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
        #NewCanisterEvent;
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

### Ethereum RPC methods
The Event Hub provides functions for interacting with Ethereum RPC methods. These functions include callEthgetLogs, callEthgetBlockByNumber, and callEthsendRawTransaction.

### Dependencies
This project depends on [evm_rpc canister](https://github.com/internet-computer-protocol/evm-rpc-canister).

## Deployment

### Mainnet
```bash
cd event_hub
dfx deploy --ic
```

#### Local
```bash
dfx start --background
```

#### Locally deploy the `evm_rpc` canister
```bash
dfx deps pull
dfx deps init evm_rpc --argument '(record { nodesInSubnet = 28 })'
dfx deps deploy
dfx deploy
```
### Contributing
Contributions are welcome. Please submit a pull request or open an issue to discuss your ideas.

### License
This project is licensed under the terms of the MIT license.
