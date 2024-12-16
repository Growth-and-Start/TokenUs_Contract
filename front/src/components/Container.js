import './styles/Container.css';

function Container({children }) {
  return (
    <div className="container-col">
      {children}
    </div>
  );
}

export default Container;
