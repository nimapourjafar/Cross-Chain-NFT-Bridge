export const getScanUrl = (chainId: string|undefined, transactionHash: string) => {
    if (chainId== "1030") {
        return `https://evm.confluxscan.net/transaction/${transactionHash}`
    }
    if (chainId== "71") {
        return `https://evmtestnet.confluxscan.net/transaction/${transactionHash}`
    }
    if (chainId== "1029") {
        return `https://confluxscan.net/transaction/${transactionHash}`
    }
    if (chainId== "1") {
        return `https://testnet.confluxscan.net/transaction/${transactionHash}`
    }
    else{
        return ""
    }
};
