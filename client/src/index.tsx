import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App";
import { completeDetect as completeDetectConflux } from "@cfxjs/use-wallet-react/conflux";
import { completeDetect as completeDetectEthereum } from "@cfxjs/use-wallet-react/ethereum";

Promise.all([completeDetectConflux(), completeDetectEthereum()]).then(() => {
  const root = ReactDOM.createRoot(
    document.getElementById("root") as HTMLElement
  );
  root.render(
    <React.StrictMode>
      <App />
    </React.StrictMode>
  );
});
