// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./CascadingSplit.sol";

// 분배 지갑 생성 컨트랙트
contract SplitFactory {
    event SplitCreated(address split, address upstream, address child, uint16 bps);

    function create(address upstream, address child, uint16 bps) external returns (address split) {
        split = address(new CascadingSplit(upstream, child, bps));
        emit SplitCreated(split, upstream, child, bps);
    }
}
