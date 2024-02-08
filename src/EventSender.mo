import Evm "canister:evm_rpc";
import Types "./Types";

module {
    type RpcSource = Types.RpcSource;
    type RpcConfig = Types.RpcConfig;
    type GetLogsArgs = Types.GetLogsArgs;
    type MultiGetLogsResult = Types.MultiGetLogsResult;

    public func eth_getLogs(source : RpcSource, config : ?RpcConfig, getLogArgs : GetLogsArgs) : async MultiGetLogsResult {
        let response = Evm.eth_getLogs(source, config, getLogArgs);
        return response;
    };
};
