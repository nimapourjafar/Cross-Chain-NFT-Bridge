import "../styles/globals.css";
import type { AppProps } from "next/app";
import { completeDetect as completeDetectConflux } from "@cfxjs/use-wallet-react/conflux";
import { completeDetect as completeDetectEthereum } from "@cfxjs/use-wallet-react/ethereum";

function MyApp({ Component, pageProps }: AppProps) {
  Promise.all([completeDetectConflux(), completeDetectEthereum()])
    return <Component {...pageProps} />;
}

export default MyApp;
