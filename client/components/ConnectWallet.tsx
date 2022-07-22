import React from "react";
import Image from "next/image";
import { useStatus, connect } from "@cfxjs/use-wallet-react/conflux/Fluent";
import {
  requestCrossNetworkPermission,
  useAccount as useCfxAccount,
} from "@cfxjs/use-wallet-react/conflux";
import { useAccount as useEvmACcount } from "@cfxjs/use-wallet-react/ethereum";
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
      <Image src={"/fluent.png"} width={20} height={20} />
    </div>
  );
}

function ConnectWalletBody() {
  const status = useStatus();
  const cfxAccount = useCfxAccount();
  const evmAccount = useEvmACcount();
  console.log(evmAccount)
  return (
    <div className="flex flex-col">
      {status == "active" &&
      cfxAccount != undefined &&
      evmAccount != undefined ? (
        <>
          <div>EVM Address: {truncateAddress(evmAccount)}</div>
          <div>CFX Address: {truncateAddress(cfxAccount)}</div>
        </>
      ) : (
        <button
          onClick={() => {
            if (status == "active") {
              requestCrossNetworkPermission();
            } else {
              connect();
            }
          }}
        >
          Connect
        </button>
      )}
    </div>
  );
}
