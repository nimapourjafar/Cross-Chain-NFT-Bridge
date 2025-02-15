import React from "react";
import logo from "./logo.svg";
import "./App.css";
import "./index.css";
import ConnectWallet from "./components/ConnectWallet";
import MainCard from "./components/MainCard";
import { Helmet } from "react-helmet";
import { ToastContainer } from "react-toastify";
import 'react-toastify/dist/ReactToastify.css';


function App() {
  return (
    <div className="container">
      <Helmet>
        <title>🚄 NFT Shuttle 🚄</title>
        <link
          rel="icon"
          href="data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 100 100%22><text y=%22.9em%22 font-size=%2290%22>🖼</text></svg>"
        />
      </Helmet>

      <nav className="flex items-center justify-between flex-wrap p-6">
        <div className="w-full block flex-grow lg:flex lg:items-center lg:w-auto">
          <div className="text-sm lg:flex-grow"></div>

          <ConnectWallet />
        </div>
      </nav>

      <main className="min-h-screen flex flex-col items-center justify-center">
        <div className="absolute top-20 space-y-2">
          <h1 className="text-3xl">Transfer NFTs</h1>

          <p className="text-lg">Between Core and eSpace</p>
          <MainCard />
        </div>
      </main>
      <ToastContainer />
    </div>
  );
}

export default App;
