// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title CascadingSplit (수익금 분배 지갑)
/// @notice 부모(upstream)/자식(child) 2수령자 구조. 부모가 Split이면 deposit() 재귀.
/// @dev 원자성 보장(실패 시 revert), 재진입 방지.
contract CascadingSplit is ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public immutable upstream;     // 부모 (다른 Split 또는 EOA)
    address public immutable child;        // 현재 창작자(EOA)
    uint16  public immutable upstreamBps;  // 부모 몫(0~10000). 자식 몫=10000-upstreamBps

    event PaidNative(address indexed to, uint256 amount);
    event PaidERC20(address indexed token, address indexed to, uint256 amount);

    constructor(address _upstream, address _child, uint16 _bps) {
        require(_child != address(0), "child=0");
        require(_bps <= 10000, "bps>10000");
        upstream = _upstream;
        child    = _child;
        upstreamBps = _bps;
    }

    // 네이티브는 반드시 deposit() 경유
    receive() external payable { revert("Use deposit()"); }

    /// @notice 네이티브 입금 → 부모/자식 분배(부모가 Split이면 재귀)
    function deposit() external payable nonReentrant { _distributeNative(msg.value); }

    function _distributeNative(uint256 amount) internal {
        if (amount == 0) return;
        uint256 u = (amount * upstreamBps) / 10000;
        uint256 c = amount - u;

        // 자식 몫
        (bool okC,) = payable(child).call{value: c}(""); 
        require(okC, "child pay");
        emit PaidNative(child, c);

        // 부모 몫(재귀 시도 → 실패면 EOA 송금)
        if (u > 0 && upstream != address(0)) {
            (bool okU,) = upstream.call{value: u}(abi.encodeWithSignature("deposit()"));
            if (!okU) { (okU,) = payable(upstream).call{value: u}(""); require(okU, "up pay"); }
            emit PaidNative(upstream, u);
        }
    }

    /// @notice ERC-20 입금 → 분배 (caller가 사전 approve 필요)
    function depositERC20(address token, uint256 amount) external nonReentrant {
        IERC20 erc = IERC20(token);
        erc.safeTransferFrom(msg.sender, address(this), amount);
        _distributeERC20(erc, amount);
    }

    /// @notice (부모가 Split이면) 보유중 토큰 재분배 트리거
    function distributeToken(address token) external nonReentrant {
        IERC20 erc = IERC20(token);
        _distributeERC20(erc, erc.balanceOf(address(this)));
    }

    function _distributeERC20(IERC20 erc, uint256 amount) internal {
        if (amount == 0) return;
        uint256 u = (amount * upstreamBps) / 10000;
        uint256 c = amount - u;

        erc.safeTransfer(child, c); emit PaidERC20(address(erc), child, c);

        if (u > 0 && upstream != address(0)) {
            erc.safeTransfer(upstream, u); emit PaidERC20(address(erc), upstream, u);
            upstream.call(abi.encodeWithSignature("distributeToken(address)", address(erc)));
        }
    }
}
