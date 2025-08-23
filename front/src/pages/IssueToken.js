import { useState } from "react";
import { useParams } from "react-router-dom";
import Web3 from "web3";
import Container from "../components/Container";
import Header from "../components/Header";
import "./styles/IssueToken.css";

// 컨트랙트 ABI 및 주소
import ChannelToken from "../contracts/Channel.json";

function IssueToken() {
  const { menu } = useParams();

  const [tokenName, setTokenName] = useState("");
  const [supplyAmount, setSupplyAmount] = useState("");
  const [loading, setLoading] = useState(false);

  const handleTokenNameChange = (e) => {
    setTokenName(e.target.value);
  };

  const handleSupplyAmountChange = (e) => {
    setSupplyAmount(e.target.value);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();

    if (!tokenName || !supplyAmount) {
      alert("토큰 이름과 발행량을 입력해주세요.");
      return;
    }

    try {
      setLoading(true);

      // Web3 인스턴스 생성
      const web3 = new Web3(window.ethereum);
      await window.ethereum.request({ method: "eth_requestAccounts" });
      const accounts = await web3.eth.getAccounts();

      // 컨트랙트 인스턴스 생성
      const networkId = await web3.eth.net.getId();
      const contractAddress = ChannelToken.networks[networkId];
      const tokenContract = new web3.eth.Contract(ChannelToken.abi, contractAddress);

      // 토큰 발행 호출
      const result = await tokenContract.methods
        .mint(tokenName, supplyAmount)
        .send({ from: accounts[0] });

      console.log("토큰 발행 성공:", result);
      alert("토큰 발행이 성공적으로 완료되었습니다!");
    } catch (error) {
      console.error("토큰 발행 오류:", error);
      alert("토큰 발행 중 오류가 발생했습니다.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <>
      <Container>
        <Header menu={menu} />

        <div className="input">
          <form onSubmit={handleSubmit}>
            <div>
              <label htmlFor="tokenName">토큰 이름:</label>
              <input
                type="text"
                id="tokenName"
                value={tokenName}
                onChange={handleTokenNameChange}
                disabled={loading}
              />
            </div>

            <div>
              <label htmlFor="supplyAmount">발행량:</label>
              <input
                type="number"
                id="supplyAmount"
                value={supplyAmount}
                onChange={handleSupplyAmountChange}
                disabled={loading}
              />
            </div>

            <button type="submit" disabled={loading}>
              {loading ? "발행 중..." : "토큰 발행"}
            </button>
          </form>
        </div>
      </Container>
    </>
  );
}

export default IssueToken;
