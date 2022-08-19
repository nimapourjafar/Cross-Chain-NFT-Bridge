import {
  useAccount as useCfxAccount,
  connect as connectCfxWallet,
  useChainId as useCfxChainId,
  switchChain as switchCfxChain,
} from "@cfxjs/use-wallet-react/conflux";
import {
  switchChain as switchEvmChain,
  useChainId as useEvmChainId,
  useAccount as useEvmAccount,
} from "@cfxjs/use-wallet-react/ethereum";
import { ethers } from "ethers";
import React, { useEffect, useState } from "react";
import { addresses } from "../addresses";
import { abis } from "../abis";
import { truncateAddress } from "../utils/truncateAddress";
import { Conflux, format } from "js-conflux-sdk";
import { toast } from "react-toastify";
import { validEvmAddress } from "../utils/validEvmAddress";
import { getScanUrl } from "../utils/getScanUrl";

export default function ESpaceToCore({
  setFlipped,
}: {
  setFlipped: (flipped: boolean) => void;
}) {
  const cfxId = useCfxChainId();
  const evmId = useEvmChainId();
  const [nftContractAddress, setNftContractAddress] = useState("");
  const [tokenIds, setTokenIds] = useState<string>("");
  const [cfxRenderId, setCfxRenderId] = useState<string | undefined>("");
  const cfxAccount = useCfxAccount();
  const evmAccount = useEvmAccount();

  useEffect(() => {
    setCfxRenderId(cfxId);
  }, [cfxId]);

  const transferTokenToCFXSide = async () => {
    console.log("calling");
    toast.info("Transfering token to CFX side...");
    // check if window is available
    if (typeof window === "undefined") {
      toast.error("window is not available");
      return;
    }
    if (!validEvmAddress(nftContractAddress)) {
      toast.error("Invalid contract address");
      return;
    }
    const conflux = new Conflux();
    // @ts-ignore
    conflux.provider = window.conflux;
    const { ethereum } = window as any;
    const provider = new ethers.providers.Web3Provider(ethereum);
    const signer = provider.getSigner();

    const evmSideContract = new ethers.Contract(
      addresses.EvmSide,
      abis.evmSide,
      signer
    );

    const nftContract = new ethers.Contract(
      nftContractAddress,
      abis.erc721,
      signer
    );

    const tokenIdsArray = tokenIds.split(",").map(Number);

    const approved = await nftContract.isApprovedForAll(
      evmAccount,
      addresses.EvmSide
    );
    if (!approved) {
      const approval = await nftContract.setApprovalForAll(
        addresses.EvmSide,
        true
      );
    }

    // TODO: check if works
    let mappedAddress = "0x0000000000000000000000000000000000000000";
    try {
      mappedAddress = await evmSideContract.sourceTokens(nftContractAddress);
    } catch (e) {
      console.log(e);
    }

    if (mappedAddress != "0x0000000000000000000000000000000000000000") {
      try {
        const tx = await evmSideContract.lockedMappedToken(
          nftContractAddress,
          format.hexAddress(cfxAccount),
          tokenIdsArray
        );
        toast.success("Token transfered to CFX side");
        toast.success(getScanUrl(evmId, tx.hash));
      } catch (e) {
        toast.error("Error locking token");
        console.log(e);
      }
    } else {
      try {
        const tx = await evmSideContract.lockToken(
          nftContractAddress,
          format.hexAddress(cfxAccount),
          tokenIdsArray
        );
        toast.success("Token transfered to CFX side");
        toast.success(getScanUrl(evmId, tx.hash));
      } catch (e) {
        toast.error("Error locking token");
        console.log(e);
      }
    }
  };

  const transferFromCfxSideToWallet = async () => {
    toast.info("Transfering token to CFX wallet...");
    if (typeof window === "undefined") {
      toast.error("window is not available");
      return;
    }
    if (!validEvmAddress(nftContractAddress)) {
      toast.error("Invalid contract address");
      return;
    }
    const conflux = new Conflux();
    // @ts-ignore
    conflux.provider = window.conflux;
    const { ethereum } = window as any;
    const provider = new ethers.providers.Web3Provider(ethereum);
    const signer = provider.getSigner();

    const confluxSideContract = conflux.Contract({
      abi: abis.cfxSide,
      address: addresses.ConfluxSide,
    });

    const evmSideContract = new ethers.Contract(
      addresses.EvmSide,
      abis.evmSide,
      signer
    );

    const tokenIdsArray = tokenIds.split(",").map(Number);
    console.log(tokenIdsArray);

    let mappedAddress = "0x0000000000000000000000000000000000000000";
    try {
      mappedAddress = await evmSideContract.sourceTokens(nftContractAddress);
    } catch (e) {
      console.log(e);
    }

    if (mappedAddress != "0x0000000000000000000000000000000000000000") {
      // nft og from cfx
      const sourceToken = await evmSideContract.sourceTokens(
        nftContractAddress
      );
      try {
        const tx = await confluxSideContract.withdrawFromEvm(
          sourceToken,
          evmAccount,
          tokenIdsArray
        );
        toast.success("Transaction completed!");
        toast.success(getScanUrl(cfxId, tx.transactionHash));
      } catch (e) {
        toast.error("Error withdrawing token");
        console.log(e);
      }
    } else {
      // nft og from evm
      console.log(cfxAccount);
      console.log(
        format.address(nftContractAddress, 1),
        format.address(evmAccount, 1),
        tokenIdsArray
      );
      try {
        const tx = await confluxSideContract
          .crossFromEvm(
            format.address(nftContractAddress, 1),
            format.address(evmAccount, 1),
            tokenIdsArray
          )
          .sendTransaction({
            from: cfxAccount,
          });
        toast.success("Transaction completed!");
        toast.success(getScanUrl(cfxId, tx.transactionHash));
      } catch (e) {
        toast.error("Error withdrawing token");
        console.log(e);
      }
    }
  };

  return (
    <div className="flex flex-col p-10 rounded-lg shadow-md space-y-2">
      <div className="flex flex-col p-5 border rounded">
        <div className="flex flex-row w-full">
          <h2>To: Conflux Core</h2>
          <button
            onClick={() => setFlipped(false)}
            className="btn-primary ml-auto"
          >
            Switch
          </button>
        </div>
        {cfxAccount != undefined ? (
          <p> {truncateAddress(cfxAccount)}</p>
        ) : (
          <button onClick={connectCfxWallet}>Connect Fluent wallet</button>
        )}
      </div>
      <div className="flex flex-col space-y-2">
        <input
          type={"text"}
          value={nftContractAddress}
          onChange={(e) => setNftContractAddress(e.target.value)}
          placeholder="NFT Contract Address"
          className="text-input w-full"
        />
        <input
          type={"text"}
          value={tokenIds}
          onChange={(e) => setTokenIds(e.target.value.replace(/[^0-9,]/g, ""))}
          placeholder="Token Ids"
          className="text-input w-full"
        />
      </div>
      <p>Step 1: Lock tokens in ESpace contract</p>
      {evmId == "71" || evmId == "1030" ? (
        <div className="flex flex-row">
          <button className="btn-primary" onClick={transferTokenToCFXSide}>
            Transfer
          </button>
        </div>
      ) : (
        <button
          className="btn-primary"
          onClick={() =>
            switchEvmChain("0x406").catch((e) => {
              toast.error(
                "Make sure you've made Fluent have priority connection!"
              );
            })
          }
        >
          Switch to ESpace
        </button>
      )}
      <p>Step 2: Wtihdraw tokens from Core Space contract</p>
      {cfxRenderId == "1029" || cfxRenderId == "1" ? (
        <button className="btn-primary" onClick={transferFromCfxSideToWallet}>
          Withdraw
        </button>
      ) : (
        <button className="btn-primary" onClick={() => switchCfxChain("0x405")}>
          Switch to Core
        </button>
      )}
    </div>
  );
}
