import "./styles/MenuButton.css"

function MenuButton({menu}) {
  return (
    <>
      <div className="menu-btn">
        <p>{menu}</p>
      </div>
    </>
  );
}
export default MenuButton;