// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Tokenus is ERC20 {
    uint public _totalSupply = 10000 * (10 ** decimals());

    constructor() ERC20("Tokenus", "TUS") {
        _mint(msg.sender, _totalSupply);
    }
}