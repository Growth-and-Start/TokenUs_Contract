// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/SplitFactory.sol";
import "../src/CascadingSplit.sol";

contract SplitFactoryTest is Test {
    SplitFactory f;
    address A = address(0xA1);
    address B = address(0xB1);

    function setUp() public { f = new SplitFactory(); }

    function test_Create_EmitsEvent_And_Works() public {
        vm.recordLogs();
        address s = f.create(A, B, 2500);
        assertTrue(s != address(0));

        // 1. Check event
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 1);

        (address split, address upstream, address child, uint16 bps) =
            abi.decode(entries[0].data, (address, address, address, uint16));

        assertEq(entries[0].topics[0], keccak256("SplitCreated(address,address,address,uint16)"));
        assertEq(split, s);
        assertEq(upstream, A);
        assertEq(child, B);
        assertEq(bps, 2500);

        // 2. Check created contract's state
        CascadingSplit splitContract = CascadingSplit(payable(s));
        assertEq(splitContract.upstream(), A);
        assertEq(splitContract.child(), B);
        assertEq(splitContract.upstreamBps(), 2500);
    }
}