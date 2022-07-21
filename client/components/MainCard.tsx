import React, { useState } from "react";
import CoreToeSpace from "./CoreToeSpace";
import ESpaceToCore from "./eSpaceToCore";


export default function MainCard() {
  const [state, setState] = useState<"CoreToeSpace" | "eSpaceToCore">(
    "CoreToeSpace"
  );
  return (
    <div className="px-4 rounded-xl bg-slate-100">{state === "CoreToeSpace" ? <CoreToeSpace /> : <ESpaceToCore />}</div>
  );
}
