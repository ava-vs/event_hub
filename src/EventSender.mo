import Evm "canister:evm_rpc";

import Cycles "mo:base/ExperimentalCycles";

import Types "./Types";

module {
    type RpcSource = Types.RpcSource;
    type RpcConfig = Types.RpcConfig;
    type GetLogsArgs = Types.GetLogsArgs;
    // type MultiGetLogsResult = Types.MultiGetLogsResult;
    type EthLogResponse = Types.LogEntry;
    let default_fee = 2_000_000_000;

    public func eth_getLogs(source : RpcSource, config : ?RpcConfig, getLogArgs : GetLogsArgs) : async Types.MultiGetLogsResult {
        Cycles.add(default_fee);
        let response = await Evm.eth_getLogs(source, config, getLogArgs);
        // parse response before return
        let parsedResponse = await _parseMultiGetLogsResult(response);
        return response;
    };

    func _parseMultiGetLogsResult(result : Types.MultiGetLogsResult) : async [EthLogResponse] {
        switch (result) {
            case (#Consistent(#Ok(logs))) { logs };
            case (#Consistent(#Err(_))) { [] };
            case (#Inconsistent(_)) { [] };
        };
    };

    public func eth_getBlockByNumber(source : RpcSource, config : ?RpcConfig, blockTag : Types.BlockTag) : async Types.MultiGetBlockByNumberResult {
        Cycles.add(default_fee);
        let response = await Evm.eth_getBlockByNumber(source, config, blockTag);
        return response;
    };

    public func eth_sendRawTransaction(source : RpcSource, config : ?RpcConfig, rawTx : Text) : async Types.MultiSendRawTransactionResult {
        Cycles.add(default_fee);
        let response = await Evm.eth_sendRawTransaction(source, config, rawTx);
        return response;
    };
};
