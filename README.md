# event_hub
Event Hub (Motoko) for Internet Computer

### Dependencies
#### Start the local replica
dfx start --background

#### Locally deploy the `evm_rpc` canister
dfx deps pull
dfx deps init evm_rpc --argument '(record { nodesInSubnet = 28 })'
dfx deps deploy

### Deploy
dfx deploy
