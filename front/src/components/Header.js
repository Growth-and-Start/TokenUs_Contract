import './styles/Header.css';

function Header({ menu }) {
  return (
    <>
      <div className="header">
        <p className='menu'>{menu}</p>
      </div>
    </>
  );
}

export default Header;