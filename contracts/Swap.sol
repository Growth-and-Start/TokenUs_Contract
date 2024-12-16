// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Tokenus.sol";
import "./Channel.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Swap {
    IERC20 public tokenus; // TUS 토큰
    IERC20 public channel; // CNL 토큰
    uint256 public rate = 100; // 1 TUS = 100 CNL

    constructor(IERC20 _tokenus, IERC20 _channel) {
        tokenus = _tokenus;
        channel = _channel;
    }

    // 컨트랙트가 사용하는 TUS 토큰 주소 반환
    function getTUSTokenAddress() public view returns (address) {
        return address(tokenus);
    }

    // 컨트랙트가 사용하는 CNL 토큰 주소 반환
    function getCNLTokenAddress() public view returns (address) {
        return address(channel);
    }

    // 사용자의 TUS 잔액 반환
    function getUserTUSBalance() public view returns (uint256) {
        return tokenus.balanceOf(msg.sender);
    }

    // 사용자의 CNL 잔액 반환
    function getUserCNLBalance() public view returns (uint256) {
        return channel.balanceOf(msg.sender);
    }

    // 컨트랙트가 보유한 CNL 유동성 확인
    function getSwapLiquidity() public view returns (uint256) {
        return channel.balanceOf(address(this));
    }

    // 현재 호출자 주소 반환
    function getMsgSender() public view returns (address) {
        return msg.sender;
    }

    // 1 TUS -> 100 CNL 교환
    function buyToken(uint256 _amountTUS) public {
        uint256 amountCNL = _amountTUS * rate; // TUS 수량 * 100 = 받을 CNL 수량

        // 1. 컨트랙트의 CNL 잔액 확인
        require(channel.balanceOf(address(this)) >= amountCNL, "Insufficient CNL liquidity in contract");

        // 2. 사용자가 컨트랙트에 TUS 전송 권한을 부여했는지 확인
        require(tokenus.allowance(msg.sender, address(this)) >= _amountTUS, "Insufficient allowance for TUS transfer");

        // 3. TUS 전송 (사용자 -> 컨트랙트)
        tokenus.transferFrom(msg.sender, address(this), _amountTUS);

        // 4. CNL 전송 (컨트랙트 -> 사용자)
        channel.transfer(msg.sender, amountCNL);
    }
}