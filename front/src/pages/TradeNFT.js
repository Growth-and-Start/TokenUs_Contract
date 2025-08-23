import { useParams } from "react-router-dom";
import Container from "../components/Container";
import Header from "../components/Header";

function TradeNFT() {
  const { menu } = useParams();

return (
  <>
    <Container>
      <Header menu={menu} />

    </Container>
  </>
)
}

export default TradeNFT;