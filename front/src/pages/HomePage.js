
import { Link } from 'react-router-dom';
import Container from '../components/Container';
import MenuButton from '../components/MenuButton';
import logo from '../assets/tokenus_logo.png';
import './styles/HomePage.css'


function MenuButtons() {
  const menus = ['토큰발행', '토큰거래', 'NFT발행', 'NFT거래'];
  return (
    <ul className='buttons'>
      {menus.map((menu) => (
        <li key={menu} className='btn'>
          <Link to={`/${menu}`}>
            <MenuButton menu={menu} />
          </Link>
        </li>
      ))}
    </ul>
  );
}


function HomePage({ account, balance }) {

  return (
    <>
      <div>
        <Container>
          <div className='title align-col'>
            <p>TokenUs</p>
            <Link to={"/"}><img src={logo} alt="로고" style={{ padding: "10px", width: "200px", height: "auto" }} /></Link>
          </div>
          <p className='account'>Connected Account : {account}</p>
          <p className='balance'>잔액 : {balance} ETH</p>
          <MenuButtons />
        </Container>
      </div>
    </>
  );
}

export default HomePage;