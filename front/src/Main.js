import { Component } from 'react';
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { useParams } from 'react-router-dom';

import HomePage from './pages/HomePage';
import IssueToken from './pages/IssueToken';
import TradeToken from './pages/TradeToken';
import TradeNFT from './pages/TradeNFT';
import MintNFT from './pages/MintNFT';

import Web3 from 'web3';

function DynamicComponent() {
  const { menu } = useParams();

  if (menu === "토큰발행") {
    return <IssueToken />;
  } else if (menu === "토큰거래") {
    return <TradeToken />;
  } else if (menu === "NFT발행") {
    return <MintNFT />;
  } else if (menu === "NFT거래") {
    return <TradeNFT />;
  }
  return <div>Not Found</div>;
}

class Main extends Component {
  constructor(props) {
    super(props);
    this.state = {
      account: "0x0",
      balance: 0,
    };
  }

  async componentDidMount() {
    await this.loadWeb3();
    await this.loadBlockchainData();
  }

  async loadWeb3() {
    if (window.ethereum) {
      window.web3 = new Web3(window.ethereum);
      await window.ethereum.enable();
    } else if (window.web3) {
      window.web3 = new Web3(window.web3.currentProvider);
    } else {
      window.alert("No ethereum browser detected. You can check out MetaMask!");
    }
  }

  async loadBlockchainData() {
    const web3 = window.web3;
    const accounts = await web3.eth.getAccounts();
    this.setState({ account: accounts[0] });
    console.log("Current Account:", accounts[0]);
    const balance = await web3.eth.getBalance(accounts[0]);

    //잔액을 이더로 변환
    const balanceEther = web3.utils.fromWei(balance,'ether');
    this.setState({balance: balanceEther})
  }

  render() {
    return (
      <BrowserRouter>
        <Routes>
          <Route index element={<HomePage account={this.state.account} balance={this.state.balance}/>} />
          <Route path=":menu" element={<DynamicComponent/>} />
        </Routes>
      </BrowserRouter>
    );
  }
}

export default Main;
