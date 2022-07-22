import React from "react";

export default function ESpaceToCore({
  setFlipped,
}: {
  setFlipped: (flipped: boolean) => void;
}) {
  return (
    <div>
      <div>
        <div className="flex flex-col">
          <h2>To Conflux Core</h2>
          <button onClick={() => setFlipped(false)}>Switch</button>
        </div>
      </div>
    </div>
  );
}
