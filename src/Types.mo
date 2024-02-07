import Blob "mo:base/Blob";
import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Result "mo:base/Result";

import E "./EventTypes";

module {

    type Auth =  { 
        #RegisterProvider; #FreeRpc; #PriorityRpc; #Manage };
// type Block =  {
//   miner : text;
//   totalDifficulty : nat;
//   receiptsRoot : text;
//   stateRoot : text;
//   hash : text;
//   difficulty : nat;
//   size : nat;
//   uncles : vec text;
//   baseFeePerGas : nat;
//   extraData : text;
//   transactionsRoot : opt text;
//   sha3Uncles : text;
//   nonce : nat;
//   number : nat;
//   timestamp : nat;
//   transactions : vec text;
//   gasLimit : nat;
//   logsBloom : text;
//   parentHash : text;
//   gasUsed : nat;
//   mixHash : text;
// };
type BlockTag = variant {
  Earliest;
  Safe;
  Finalized;
  Latest;
  Number : nat;
  Pending;
};
type EthMainnetService = variant {
  Alchemy;
  BlockPi;
  Cloudflare;
  PublicNode;
  Ankr;
};
type EthSepoliaService = variant { Alchemy; BlockPi; PublicNode; Ankr };
type FeeHistory = record {
  reward : vec vec nat;
  gasUsedRatio : vec float64;
  oldestBlock : nat;
  baseFeePerGas : vec nat;
};
type FeeHistoryArgs = record {
  blockCount : nat;
  newestBlock : BlockTag;
  rewardPercentiles : opt vec nat8;
};
type FeeHistoryResult = variant { Ok : opt FeeHistory; Err : RpcError };
type GetBlockByNumberResult = variant { Ok : Block; Err : RpcError };
type GetLogsArgs = record {
  fromBlock : opt BlockTag;
  toBlock : opt BlockTag;
  addresses : vec text;
  topics : opt vec vec text;
};
type GetLogsResult = variant { Ok : vec LogEntry; Err : RpcError };
type GetTransactionCountArgs = record { address : text; block : BlockTag };
type GetTransactionCountResult = variant { Ok : nat; Err : RpcError };
type GetTransactionReceiptResult = variant {
  Ok : opt TransactionReceipt;
  Err : RpcError;
};
type HttpHeader = record { value : text; name : text };
type HttpOutcallError = variant {
  IcError : record { code : RejectionCode; message : text };
  InvalidHttpJsonRpcResponse : record {
    status : nat16;
    body : text;
    parsingError : opt text;
  };
};
type InitArgs = record { nodesInSubnet : nat32 };
type JsonRpcError = record { code : int64; message : text };
type JsonRpcSource = variant {
  Custom : record { url : text; headers : opt vec HttpHeader };
  Service : record { hostname : text; chainId : opt nat64 };
  Chain : nat64;
  Provider : nat64;
};
type LogEntry = record {
  transactionHash : opt text;
  blockNumber : opt nat;
  data : text;
  blockHash : opt text;
  transactionIndex : opt nat;
  topics : vec text;
  address : text;
  logIndex : opt nat;
  removed : bool;
};
type ManageProviderArgs = record {
  "service" : opt RpcService;
  primary : opt bool;
  providerId : nat64;
};
type Metrics = record {
  cyclesWithdrawn : nat;
  responses : vec record { record { text; text; text }; nat64 };
  errNoPermission : nat64;
  inconsistentResponses : vec record { record { text; text }; nat64 };
  cyclesCharged : vec record { record { text; text }; nat };
  requests : vec record { record { text; text }; nat64 };
  errHttpOutcall : vec record { record { text; text }; nat64 };
  errHostNotAllowed : vec record { text; nat64 };
};
type MultiFeeHistoryResult = variant {
  Consistent : FeeHistoryResult;
  Inconsistent : vec record { RpcService; FeeHistoryResult };
};
type MultiGetBlockByNumberResult = variant {
  Consistent : GetBlockByNumberResult;
  Inconsistent : vec record { RpcService; GetBlockByNumberResult };
};
type MultiGetLogsResult = variant {
  Consistent : GetLogsResult;
  Inconsistent : vec record { RpcService; GetLogsResult };
};
type MultiGetTransactionCountResult = variant {
  Consistent : GetTransactionCountResult;
  Inconsistent : vec record { RpcService; GetTransactionCountResult };
};
type MultiGetTransactionReceiptResult = variant {
  Consistent : GetTransactionReceiptResult;
  Inconsistent : vec record { RpcService; GetTransactionReceiptResult };
};
type MultiSendRawTransactionResult = variant {
  Consistent : SendRawTransactionResult;
  Inconsistent : vec record { RpcService; SendRawTransactionResult };
};
type ProviderError = variant {
  TooFewCycles : record { expected : nat; received : nat };
  MissingRequiredProvider;
  ProviderNotFound;
  NoPermission;
};
type ProviderView = record {
  cyclesPerCall : nat64;
  owner : principal;
  hostname : text;
  primary : bool;
  chainId : nat64;
  cyclesPerMessageByte : nat64;
  providerId : nat64;
};
type RegisterProviderArgs = record {
  cyclesPerCall : nat64;
  credentialPath : text;
  hostname : text;
  credentialHeaders : opt vec HttpHeader;
  chainId : nat64;
  cyclesPerMessageByte : nat64;
};
type RejectionCode = variant {
  NoError;
  CanisterError;
  SysTransient;
  DestinationInvalid;
  Unknown;
  SysFatal;
  CanisterReject;
};
type RequestCostResult = variant { Ok : nat; Err : RpcError };
type RequestResult = variant { Ok : text; Err : RpcError };
type RpcConfig = record { responseSizeEstimate : opt nat64 };
type RpcError = variant {
  JsonRpcError : JsonRpcError;
  ProviderError : ProviderError;
  ValidationError : ValidationError;
  HttpOutcallError : HttpOutcallError;
};
type RpcService = variant {
  EthSepolia : EthSepoliaService;
  EthMainnet : EthMainnetService;
};
type RpcSource = variant {
  EthSepolia : opt vec EthSepoliaService;
  EthMainnet : opt vec EthMainnetService;
};
type SendRawTransactionResult = variant {
  Ok : SendRawTransactionStatus;
  Err : RpcError;
};
type SendRawTransactionStatus = variant {
  Ok;
  NonceTooLow;
  NonceTooHigh;
  InsufficientFunds;
};
type TransactionReceipt = record {
  to : text;
  status : nat;
  transactionHash : text;
  blockNumber : nat;
  from : text;
  logs : vec LogEntry;
  blockHash : text;
  "type" : text;
  transactionIndex : nat;
  effectiveGasPrice : nat;
  logsBloom : text;
  contractAddress : opt text;
  gasUsed : nat;
};
type UpdateProviderArgs = record {
  cyclesPerCall : opt nat64;
  credentialPath : opt text;
  hostname : opt text;
  credentialHeaders : opt vec HttpHeader;
  primary : opt bool;
  cyclesPerMessageByte : opt nat64;
  providerId : nat64;
};
type ValidationError = variant {
  CredentialPathNotAllowed;
  HostNotAllowed : text;
  CredentialHeaderNotAllowed;
  UrlParseError : text;
  Custom : text;
  InvalidHex : text;
};
// service : {
//   authorize : (principal, Auth) -> (bool);
//   deauthorize : (principal, Auth) -> (bool);
//   eth_feeHistory : (RpcSource, opt RpcConfig, FeeHistoryArgs) -> (
//       MultiFeeHistoryResult,
//     );
//   eth_getBlockByNumber : (RpcSource, opt RpcConfig, BlockTag) -> (
//       MultiGetBlockByNumberResult,
//     );
//   eth_getLogs : (RpcSource, opt RpcConfig, GetLogsArgs) -> (MultiGetLogsResult);
//   eth_getTransactionCount : (
//       RpcSource,
//       opt RpcConfig,
//       GetTransactionCountArgs,
//     ) -> (MultiGetTransactionCountResult);
//   eth_getTransactionReceipt : (RpcSource, opt RpcConfig, text) -> (
//       MultiGetTransactionReceiptResult,
//     );
//   eth_sendRawTransaction : (RpcSource, opt RpcConfig, text) -> (
//       MultiSendRawTransactionResult,
//     );
//   getAccumulatedCycleCount : (nat64) -> (nat) query;
//   getAuthorized : (Auth) -> (vec principal) query;
//   getMetrics : () -> (Metrics) query;
//   getNodesInSubnet : () -> (nat32) query;
//   getOpenRpcAccess : () -> (bool) query;
//   getProviders : () -> (vec ProviderView) query;
//   getServiceProviderMap : () -> (vec record { RpcService; nat64 }) query;
//   manageProvider : (ManageProviderArgs) -> ();
//   registerProvider : (RegisterProviderArgs) -> (nat64);
//   request : (JsonRpcSource, text, nat64) -> (RequestResult);
//   requestCost : (JsonRpcSource, text, nat64) -> (RequestCostResult) query;
//   setOpenRpcAccess : (bool) -> ();
//   unregisterProvider : (nat64) -> (bool);
//   updateProvider : (UpdateProviderArgs) -> ();
//   withdrawAccumulatedCycles : (nat64, principal) -> ();
}

    // public type EventFilter = {
    //     eventType : ?E.EventName;
    //     fieldFilters : [E.EventField];
    // };

    // public type RemoteCallEndpoint = {
    //     canisterId : Principal.Principal;
    //     methodName : Text;
    // };

    // public type EncodedEventBatch = {
    //     content : Blob;
    //     eventsCount : Nat;
    //     timestamp : Int;
    // };

    // public type Subscriber = {
    //     callback : Principal; // subscriber's canister_id
    //     filter : EventFilter;
    // };

    // public type ApiError = {
    //     #Unauthorized;
    //     #InvalidTokenId;
    //     #ZeroAddress;
    //     #NoNFT;
    //     #Other;
    // };

    // public type Result<S, E> = {
    //     #Ok : S;
    //     #Err : E;
    // };

    // // Reputation part

    // public type Branch = Nat8;

    // public type DocHistory = {
    //     docId : DocId;
    //     timestamp : Int;
    //     changedBy : Principal;
    //     value : Nat8;
    //     comment : Text;
    // };

    // public type CommonError = {
    //     #InsufficientFunds : { balance : Tokens };
    //     #BadFee : { expected_fee : Tokens };
    //     #TemporarilyUnavailable;
    //     #GenericError : { error_code : Nat; message : Text };
    //     #NotFound : { message : Text; docId : DocId };
    // };

    // public type Tokens = Nat;
    // public type DocId = Nat;
};
