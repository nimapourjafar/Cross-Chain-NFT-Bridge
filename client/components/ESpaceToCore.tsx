import {
  useAccount as useCfxAccount,
  useStatus,
  connect as connectCfxWallet,
} from "@cfxjs/use-wallet-react/conflux/Fluent";
import { useAccount as useEvmAccount } from "@cfxjs/use-wallet-react/ethereum";
import { ethers } from "ethers";
import React, { useState } from "react";
import { addresses } from "../addresses";
import { abi as EvmABI } from "../../artifacts/contracts/EvmSideERC721.sol/EvmSide.json";
import { abi as CfxABI } from "../../artifacts/contracts/ConfluxSideERC721.sol/ConfluxSideERC721.json";
import { abi as NftABI } from "../../artifacts/contracts/UpgradeableERC721.sol/UpgradeableERC721.json";
import { truncateAddress } from "../utils/truncateAddress";
import { Conflux, format } from "js-conflux-sdk";

export default function ESpaceToCore({
  setFlipped,
}: {
  setFlipped: (flipped: boolean) => void;
}) {
  const cfxStatus = useStatus();
  const [nftContractAddress, setNftContractAddress] = useState("");
  const [tokenIds, setTokenIds] = useState<string>("");
  const cfxAccount = useCfxAccount();
  const evmAccount = useEvmAccount();

  const transferTokenToCFXSide = async () => {
    const conflux = new Conflux();
    // @ts-ignore
    conflux.provider = window.conflux;
    const { ethereum } = window as any;
    const provider = new ethers.providers.Web3Provider(ethereum);
    const signer = provider.getSigner();

    const evmSideContract = new ethers.Contract(
      addresses.EvmSide,
      EvmABI,
      signer
    );

    const nftContract = new ethers.Contract(nftContractAddress, NftABI, signer);

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

    // check if evm address maps to cfx side address
    let mappedAddress = "0x0000000000000000000000000000000000000000";
    try {
      mappedAddress = await evmSideContract.sourceTokens(nftContractAddress);
    } catch (e) {
      console.log(e);
    }
    console.log("mapped", mappedAddress);

    if (mappedAddress != "0x0000000000000000000000000000000000000000") {
      const tx = await evmSideContract.lockedMappedToken(
        nftContractAddress,
        format.hexAddress(cfxAccount),
        tokenIdsArray
      );
      console.log(tx);
    } else {
      const tx = await evmSideContract.lockToken(
        nftContractAddress,
        format.hexAddress(cfxAccount),
        tokenIdsArray
      );
      console.log(tx);
    }
  };

  const transferFromCfxSideToWallet = async () => {
    const conflux = new Conflux();
    // @ts-ignore
    conflux.provider = window.conflux;
    const { ethereum } = window as any;
    const provider = new ethers.providers.Web3Provider(ethereum);
    const signer = provider.getSigner();

    const confluxSideContract = conflux.Contract({
      abi: CfxABI,
      address: addresses.ConfluxSide,
    });

    const evmSideContract = new ethers.Contract(
      addresses.EvmSide,
      EvmABI,
      signer
    );

    const tokenIdsArray = tokenIds.split(",").map(Number);
    console.log(tokenIdsArray)

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
      const tx = await confluxSideContract.withdrawFromEvm(
        sourceToken,
        evmAccount,
        tokenIdsArray
      );
    } else {
      // nft og from evm
      console.log(cfxAccount)
      console.log(format.address(nftContractAddress,1),format.address(evmAccount,1),tokenIdsArray)
      const tx = await confluxSideContract.crossFromEvm(
        format.address(nftContractAddress,1),
        format.address(evmAccount,1),
        tokenIdsArray
      );
    }
  };

  return (
    <div className="flex flex-col p-10 rounded-lg shadow-md space-y-2">
      <div className="flex flex-col p-5 border rounded">
        <div className="flex flex-row justify-start">
          <h2>To: Conflux Core</h2>
          <button onClick={() => setFlipped(false)}>Switch</button>
        </div>
        {cfxStatus == "active" ? (
          <p> {truncateAddress(cfxAccount || "")}</p>
        ) : (
          <button onClick={connectCfxWallet}>Connect Fluent wallet</button>
        )}
      </div>
      <div>
        <input
          type={"text"}
          value={nftContractAddress}
          onChange={(e) => setNftContractAddress(e.target.value)}
          placeholder="NFT Contract Address"
          className="text-input w-full"
        />
      </div>
      <div className="flex flex-col">
        <div className="flex flex-col">
          <div className="flex flex-row">
            <p>Step 1</p>
            <p>Transfer Token</p>
          </div>
          <p>Transfer NFTs to cross space bridge</p>
        </div>
        <div className="flex flex-row">
          <input
            type={"text"}
            value={tokenIds}
            onChange={(e) =>
              setTokenIds(e.target.value.replace(/[^0-9,]/g, ""))
            }
            placeholder="Token Ids"
            className="text-input w-full"
          />
          <button onClick={transferTokenToCFXSide}>Transfer</button>
        </div>
      </div>
      <button onClick={transferFromCfxSideToWallet}>Withdraw</button>
    </div>
  );
}