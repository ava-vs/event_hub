import Evm "canister:evm_rpc";
import Cycles "mo:base/ExperimentalCycles";
import Types "./Types";

module {
    type RpcSource = Types.RpcSource;
    type RpcConfig = Types.RpcConfig;
    type GetLogsArgs = Types.GetLogsArgs;
    // type MultiGetLogsResult = Types.MultiGetLogsResult;
    type EthLogResponse = Types.LogEntry;
    let default_fee = 300_000_000;

    public func eth_getLogs(source : RpcSource, config : ?RpcConfig, getLogArgs : GetLogsArgs) : async Types.MultiGetLogsResult {
        Cycles.add(default_fee);
        let response = await Evm.eth_getLogs(source, config, getLogArgs);
        // parse response before return
        let parsedResponse = await parseMultiGetLogsResult(response);
        return response;
    };

    public func parseMultiGetLogsResult(result : Types.MultiGetLogsResult) : async [EthLogResponse] {
        switch (result) {
            case (#Consistent(#Ok(logs))) { logs };
            case (#Consistent(#Err(_))) { [] };
            case (#Inconsistent(_)) { [] };
        };
    };
};
