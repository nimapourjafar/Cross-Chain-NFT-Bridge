import { useAccount } from "@cfxjs/use-wallet-react/ethereum";
import React, { useState } from "react";

export default function CoreToeSpace({
  setFlipped,
}: {
  setFlipped: (flipped: boolean) => void;
}) {
  const [eSpaceAddress, setESpaceAddress] = useState("");
  const [nftContractAddress, setNftContractAddress] = useState("");
  const [tokenIds, setTokenIds] = useState<string>("");
  const evmAccount = useAccount();


  const approveNFTs = async () => {
  }

  return (
    <div className="flex flex-col p-10 rounded-lg shadow-md space-y-2">
      <div className="flex flex-col p-5 border rounded">
        <div className="flex flex-row justify-start">
          <h2>To: Conflux eSpace</h2>
          <button onClick={() => setFlipped(true)}>Switch</button>
        </div>
        <div className="flex flex-row">
          <input
            type="text"
            value={eSpaceAddress}
            onChange={(e) => setESpaceAddress(e.target.value)}
            placeholder="eSpace Address"
            className="text-input w-full"
          />
          <button
            onClick={() => {
              if (evmAccount !== undefined) {
                setESpaceAddress(evmAccount);
              }
            }}
          >
            Curr Addr
          </button>
        </div>
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
          onChange={(e) =>
            setTokenIds(e.target.value.replace(/[^0-9,]/g, ""))
          }
          placeholder="Token Ids"
          className="text-input w-full"
        />
        <button onClick={approveNFTs}>
          Approve NFTs
        </button>
      </div>
    </div>
  );
}
