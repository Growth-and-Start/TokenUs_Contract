// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/CascadingSplit.sol";

contract CascadingSplitTest is Test {
    address A = address(0xA1); // upstream
    address B = address(0xB1); // child
    CascadingSplit split;

    function setUp() public {
        split = new CascadingSplit(A, B, 3000); // 30% up
        vm.deal(address(this), 100 ether);
        vm.deal(A, 0); vm.deal(B, 0);
    }

    // EOA 부모로의 단순 송금. Split_B → A(EOA)
    function test_Distribute_Native_ToEOAParent() public {
        split.deposit{value: 1 ether}();
        assertEq(A.balance, 0.3 ether);
        assertEq(B.balance, 0.7 ether);
    }

    // 재귀 분배. Split_C → Split_B → A(EOA)
    function test_Distribute_Recursive_UpToSplit() public {
        address C = address(0xC1);
        CascadingSplit up = new CascadingSplit(A, B, 3000);       // 30% to A
        CascadingSplit me = new CascadingSplit(address(up), C, 3000); // 30% up to 'up'

        me.deposit{value: 1 ether}();
        // C 0.7, up 0.3 → up splits to A 0.09, B 0.21
        assertEq(C.balance, 0.7 ether);
        assertEq(B.balance, 0.21 ether);
        assertEq(A.balance, 0.09 ether);
    }

    // function test_Distribute_ERC20() public {
    //     MockERC20 t = new MockERC20("M","M");
    //     t.mint(address(this), 1000 ether);
    //     t.approve(address(split), 1000 ether);
    //     split.depositERC20(address(t), 100 ether);
    //     assertEq(t.balanceOf(A), 30 ether);
    //     assertEq(t.balanceOf(B), 70 ether);
    // }

    // upstreamBps > 10000로 생성 시 revert 확인
    function test_Revert_When_Bps_OverMax() public {
        vm.expectRevert(); // constructor require(bps<=10000)
        new CascadingSplit(A, B, 10001);
    }

    // 0 입금 시 아무 변화 없음을 확인
    function test_Deposit_Zero_NoEffect() public {
        uint256 a0=A.balance; uint256 b0=B.balance;
        // 직접 native 송금은 막음(receive revert) → deposit(0)만 허용
        split.deposit{value: 0}();
        assertEq(A.balance, a0);
        assertEq(B.balance, b0);
    }
}
