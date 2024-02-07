import Blob "mo:base/Blob";
import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Result "mo:base/Result";

import E "./EventTypes";

module {

  public type Auth = {
    #RegisterProvider;
    #FreeRpc;
    #PriorityRpc;
    #Manage;
  };

  public type Block = {
    miner : Text;
    totalDifficulty : Nat;
    receiptsRoot : Text;
    stateRoot : Text;
    hash : Text;
    difficulty : Nat;
    size : Nat;
    uncles : [Text];
    baseFeePerGas : Nat;
    extraData : Text;
    transactionsRoot : ?Text;
    sha3Uncles : Text;
    nonce : Nat;
    number : Nat;
    timestamp : Nat;
    transactions : [Text];
    gasLimit : Nat;
    logsBloom : Text;
    parentHash : Text;
    gasUsed : Nat;
    mixHash : Text;
  };

  public type BlockTag = {
    #Earliest;
    #Safe;
    #Finalized;
    #Latest;
    #Number : Nat;
    #Pending;
  };

  public type EthMainnetService = {
    #Alchemy;
    #BlockPi;
    #Cloudflare;
    #PublicNode;
    #Ankr;
  };

  public type EthSepoliaService = {
    #Alchemy;
    #BlockPi;
    #PublicNode;
    #Ankr;
  };

  public type FeeHistory = {
    reward : [[Nat]];
    gasUsedRatio : [Float];
    oldestBlock : Nat;
    baseFeePerGas : [Nat];
  };

  public type FeeHistoryArgs = {
    blockCount : Nat;
    newestBlock : BlockTag;
    rewardPercentiles : ?[Nat8];
  };

  public type FeeHistoryResult = {
    #Ok : ?FeeHistory;
    #Err : RpcError;
  };

  public type GetBlockByNumberResult = {
    #Ok : Block;
    #Err : RpcError;
  };

  public type GetLogsArgs = {
    fromBlock : ?BlockTag;
    toBlock : ?BlockTag;
    addresses : [Text];
    topics : ?[[Text]];
  };

  public type GetLogsResult = {
    #Ok : [LogEntry];
    #Err : RpcError;
  };

  public type GetTransactionCountArgs = {
    address : Text;
    block : BlockTag;
  };

  public type GetTransactionCountResult = {
    #Ok : Nat;
    #Err : RpcError;
  };

  public type GetTransactionReceiptResult = {
    #Ok : ?TransactionReceipt;
    #Err : RpcError;
  };

  public type HttpHeader = {
    value : Text;
    name : Text;
  };

  public type HttpOutcallError = {
    #IcError : { code : RejectionCode; message : Text };
    #InvalidHttpJsonRpcResponse : {
      status : Nat16;
      body : Text;
      parsingError : ?Text;
    };
  };

  public type InitArgs = { nodesInSubnet : Nat32 };

  public type JsonRpcError = { code : Int64; message : Text };

  public type JsonRpcSource = {
    #Custom : { url : Text; headers : ?[HttpHeader] };
    #Service : { hostname : Text; chainId : ?Nat64 };
    #Chain : Nat64;
    #Provider : Nat64;
  };

  public type LogEntry = {
    transactionHash : ?Text;
    blockNumber : ?Nat;
    data : Text;
    blockHash : ?Text;
    transactionIndex : ?Nat;
    topics : [Text];
    address : Text;
    logIndex : ?Nat;
    removed : Bool;
  };

  public type ManageProviderArgs = {
    service : ?RpcService;
    primary : ?Bool;
    providerId : Nat64;
  };

  // public type Metrics = {
  //   cyclesWithdrawn: Nat;
  //   responses: [({Text; Text; Text}, Nat64)];
  //   errNoPermission: Nat64;
  //   inconsistentResponses: [({Text; Text}, Nat64)];
  //   cyclesCharged: [({Text; Text}, Nat)];
  //   requests: [({Text; Text}, Nat64)];
  //   errHttpOutcall: [({Text; Text}, Nat64)];
  //   errHostNotAllowed: [(Text, Nat64)];
  // };

  public type MultiFeeHistoryResult = {
    #Consistent : FeeHistoryResult;
    #Inconsistent : [(RpcService, FeeHistoryResult)];
  };

  public type MultiGetBlockByNumberResult = {
    #Consistent : GetBlockByNumberResult;
    #Inconsistent : [(RpcService, GetBlockByNumberResult)];
  };

  public type MultiGetLogsResult = {
    #Consistent : GetLogsResult;
    #Inconsistent : [(RpcService, GetLogsResult)];
  };

  public type MultiGetTransactionCountResult = {
    #Consistent : GetTransactionCountResult;
    #Inconsistent : [(RpcService, GetTransactionCountResult)];
  };

  public type MultiGetTransactionReceiptResult = {
    #Consistent : GetTransactionReceiptResult;
    #Inconsistent : [(RpcService, GetTransactionReceiptResult)];
  };

  public type MultiSendRawTransactionResult = {
    #Consistent : SendRawTransactionResult;
    #Inconsistent : [(RpcService, SendRawTransactionResult)];
  };

  public type ProviderError = {
    #TooFewCycles : { expected : Nat; received : Nat };
    #MissingRequiredProvider;
    #ProviderNotFound;
    #NoPermission;
  };

  public type ProviderView = {
    cyclesPerCall : Nat64;
    owner : Principal;
    hostname : Text;
    primary : Bool;
    chainId : Nat64;
    cyclesPerMessageByte : Nat64;
    providerId : Nat64;
  };

  public type RegisterProviderArgs = {
    cyclesPerCall : Nat64;
    credentialPath : Text;
    hostname : Text;
    credentialHeaders : ?[HttpHeader];
    chainId : Nat64;
    cyclesPerMessageByte : Nat64;
  };

  public type RejectionCode = {
    #NoError;
    #CanisterError;
    #SysTransient;
    #DestinationInvalid;
    #Unknown;
    #SysFatal;
    #CanisterReject;
  };

  public type RequestCostResult = {
    #Ok : Nat;
    #Err : RpcError;
  };

  public type RequestResult = {
    #Ok : Text;
    #Err : RpcError;
  };

  public type RpcConfig = { responseSizeEstimate : ?Nat64 };

  public type RpcError = {
    #JsonRpcError : JsonRpcError;
    #ProviderError : ProviderError;
    #ValidationError : ValidationError;
    #HttpOutcallError : HttpOutcallError;
  };

  public type RpcService = {
    #EthSepolia : EthSepoliaService;
    #EthMainnet : EthMainnetService;
  };

  public type RpcSource = {
    #EthSepolia : ?[EthSepoliaService];
    #EthMainnet : ?[EthMainnetService];
  };

  public type SendRawTransactionResult = {
    #Ok : SendRawTransactionStatus;
    #Err : RpcError;
  };

  public type SendRawTransactionStatus = {
    #Ok;
    #NonceTooLow;
    #NonceTooHigh;
    #InsufficientFunds;
  };

  public type TransactionReceipt = {
    to : Text;
    status : Nat;
    transactionHash : Text;
    blockNumber : Nat;
    from : Text;
    logs : [LogEntry];
    blockHash : Text;
    txtype : Text;
    transactionIndex : Nat;
    effectiveGasPrice : Nat;
    logsBloom : Text;
    contractAddress : ?Text;
    gasUsed : Nat;
  };

  public type UpdateProviderArgs = {
    cyclesPerCall : ?Nat64;
    credentialPath : ?Text;
    hostname : ?Text;
    credentialHeaders : ?[HttpHeader];
    primary : ?Bool;
    cyclesPerMessageByte : ?Nat64;
    providerId : Nat64;
  };

  public type ValidationError = {
    #CredentialPathNotAllowed;
    #HostNotAllowed : Text;
    #CredentialHeaderNotAllowed;
    #UrlParseError : Text;
    #Custom : Text;
    #InvalidHex : Text;
  };

};
