import React from "react";
import Image from "next/image";
import { useStatus as useCfxStatus } from "@cfxjs/use-wallet-react/conflux";
import { useStatus as useEvmStatus } from "@cfxjs/use-wallet-react/ethereum";
import DropDown from "./DropDown";
export default function ConnectWallet() {
  return (
    <>
      <DropDown
        titleComponent={<ConnectWalletTitle />}
        bodyComponent={<ConnectWalletTitle />}
      />
    </>
  );
}

function ConnectWalletTitle() {
  const cfxStatus = useCfxStatus();
  const evmStatus = useEvmStatus();
  return (
    <div className="flex flex-row">
      {cfxStatus == "active" && evmStatus === "active" && (
        <div>You are connected!</div>
      )}
      <Image src={"/fluent.png"} width={20} height={20} />
    </div>
  );
}

function ConnectWalletBody() {
  return <div>Connect wallet body</div>;
}

function ConnectEVM() {
  return <div>ConnectEVM</div>;
}

function ConnectCore() {
  return <div>ConnectCore</div>;
}
