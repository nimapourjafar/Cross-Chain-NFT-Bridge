

import React from "react";
import {
  useStatus,
  connect,
  useAccount as useCfxAccount,
} from "@cfxjs/use-wallet-react/conflux";

import { useAccount as useEvmACcount , connect as connectEvm} from "@cfxjs/use-wallet-react/ethereum";
import DropDown from "./DropDown";
import { truncateAddress } from "../utils/truncateAddress";
export default function ConnectWallet() {
  return (
    <>
      <DropDown
        titleComponent={<ConnectWalletTitle />}
        bodyComponent={<ConnectWalletBody />}
      />
    </>
  );
}

function ConnectWalletTitle() {
  const status = useStatus();
  return (
    <div className="flex flex-row">
      {status == "active" ? (
        <div>You are connected!</div>
      ) : (
        <div>Connect your wallet</div>
      )}
    </div>
  );
}

function ConnectWalletBody() {
  const status = useStatus();
  const cfxAccount = useCfxAccount();
  const evmAccount = useEvmACcount();
  console.log(evmAccount);
  return (
    <div className="flex flex-col">
      {status == "active" ? (
        <>
          <div>EVM Address: {truncateAddress(evmAccount||"")}</div>
          <div>CFX Address: {truncateAddress(cfxAccount||"")}</div>
        </>
      ) : (
        <button
          onClick={() => {
            connect();
            connectEvm();
          }}
        >
          Connect
        </button>
      )}
    </div>
  );
}