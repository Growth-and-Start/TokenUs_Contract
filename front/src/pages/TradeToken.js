import { useState } from "react";
import { useParams } from "react-router-dom";
import Container from "../components/Container";
import Header from "../components/Header";

function TradeToken() {
  const { menu } = useParams();

  // const [receiverAddress, setReceiverAddress] = useState("");
  const [amount, setAmount] = useState("");
  const [account, setAccount] = useState(null);

  // const handleReceiverAddressChange = (e) => {
  //   setReceiverAddress(e.target.value);
  // };

  const handleAmountChange = (e) => {
    setAmount(e.target.value);
  };

  //토큰 전송 컨트랙트 연결
  const handleSubmit = async (e) =>{

  }

  return (
    <>
      <Container>
        <Header menu={menu} />
        <form onSubmit={handleSubmit}>
          {/* <div>
            <label htmlFor="receiverAddress">받는 사람 주소:</label>
            <input
              type="text"
              id="receiverAddress"
              value={receiverAddress}
              onChange={handleReceiverAddressChange}
    
            />
          </div> */}

          <div>
            <label htmlFor="amount">구매 수량:</label>
            <input
              type="number"
              id="amount"
              value={amount}
              onChange={handleAmountChange}
          
            />
          </div>
          <p>1 CNL = 0.01 TUS</p>

          <button type="submit">토큰 구매</button>
        </form>

        {account && <p>현재 연결된 계정: {account}</p>}
      </Container>
    </>
  );
}

export default TradeToken;