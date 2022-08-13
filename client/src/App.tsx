import React from 'react';
import logo from './logo.svg';
import './App.css';
import "./index.css"
import ConnectWallet from './components/ConnectWallet';
import MainCard from './components/MainCard';

function App() {
  return (
    <div className='container' >

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
    </div>
  )
}

export default App;
