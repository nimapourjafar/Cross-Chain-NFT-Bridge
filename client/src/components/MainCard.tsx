import React, { useState } from "react";
import CoreToeSpace from "./CoreToeSpace";
import ESpaceToCore from "./ESpaceToCore";
import ReactCardFlip from "react-card-flip";

export default function MainCard() {
  const [flipped, setFlipped] = useState(false);
  return (
    <div className=" w-[30rem]">
      <ReactCardFlip flipDirection="horizontal" isFlipped={flipped}>
        <CoreToeSpace setFlipped={setFlipped} />
        <ESpaceToCore setFlipped={setFlipped} />
      </ReactCardFlip>
    </div>
  );
}