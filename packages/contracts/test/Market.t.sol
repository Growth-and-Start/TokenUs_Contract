// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import "../src/NFT.sol";
import "../src/Market.sol";
import "../src/CascadingSplit.sol";

contract MarketAllTest is Test {
    NFT nft;
    Market market;

    address feeVault= address(0xFEE);
    address admin   = address(this);
    address A       = address(0xA);   // 원작자
    address B       = address(0xB);   // 파생자
    address S       = address(0x5E);  // 판매자(초기 소유자)
    address U1      = address(0x1111);  // 구매자1
    address U2      = address(0x2222);  // 구매자2

    uint256 constant P1 = 1 ether; // 1차가
    uint256 constant P2 = 2 ether; // 2차가

    function setUp() public {
        nft = new NFT();
        market = new Market(feeVault);
        vm.deal(feeVault,0);
        vm.deal(A,10 ether); vm.deal(B,10 ether);
        vm.deal(S,10 ether); vm.deal(U1,10 ether); vm.deal(U2,10 ether);
    }

    // ── 공통 헬퍼
    function _approveAndList(address owner, uint256 tokenId, uint256 price, bool isPrimary) internal {
        vm.startPrank(owner);
        nft.setApprovalForAll(address(market), true);
        market.list(address(nft), tokenId, price, isPrimary);
        vm.stopPrank();
    }

    // 1) 원본, split 없음
    function test_Original_NoSplit_Primary_Secondary() public {
        nft.createOriginalWork(1, A, address(0));
        uint256[] memory ids = nft.mintEditionBatch(S, 1, 1);
        uint256 t = ids[0];

        _approveAndList(S, t, P1, true);

        uint256 fee0 = feeVault.balance;
        uint256 s0   = S.balance;

        vm.prank(U1);
        market.buy{value:P1}(address(nft), t);

        assertEq(feeVault.balance - fee0, 0.025 ether);
        assertApproxEqAbs(S.balance - s0, 0.975 ether, 1 wei);
        assertEq(nft.ownerOf(t), U1);
        assertTrue(market.primarySold(address(nft), t));

        // 2차: U1 → U2
        _approveAndList(U1, t, P2, false);

        uint256 fee1 = feeVault.balance;
        uint256 u1   = U1.balance;
        uint256 a0   = A.balance;

        vm.prank(U2);
        market.buy{value:P2}(address(nft), t);

        assertEq(feeVault.balance - fee1, 0.05 ether);
        // 로열티 10% of price = 0.2 → split 없음 → A에게 직지급
        assertApproxEqAbs(A.balance - a0, 0.2 ether, 1 wei);
        // 나머지 1.75 U1
        assertApproxEqAbs(U1.balance - u1, 1.75 ether, 1 wei);
        assertEq(nft.ownerOf(t), U2);
    }

    // 2) 원본, split 있음(예: 전액 creator 분배)
    function test_Original_WithSplit_Primary_Secondary() public {
        CascadingSplit sA = new CascadingSplit(address(0), A, 0);
        nft.createOriginalWork(2, A, address(sA));
        uint256[] memory ids = nft.mintEditionBatch(S, 2, 1);
        uint256 t = ids[0];

        _approveAndList(S, t, P1, true);

        uint256 fee0 = feeVault.balance;
        uint256 a0   = A.balance;

        vm.prank(U1);
        market.buy{value:P1}(address(nft), t);

        assertEq(feeVault.balance - fee0, 0.025 ether);
        assertApproxEqAbs(A.balance - a0, 0.975 ether, 1 wei); // 전액 split → A
        assertEq(nft.ownerOf(t), U1);

        _approveAndList(U1, t, P2, false);

        uint256 fee1 = feeVault.balance;
        uint256 u10  = U1.balance;
        a0 = A.balance;

        vm.prank(U2);
        market.buy{value:P2}(address(nft), t);

        assertEq(feeVault.balance - fee1, 0.05 ether);
        assertApproxEqAbs(A.balance - a0, 0.2 ether, 1 wei); // 로열티 전액 A
        assertApproxEqAbs(U1.balance - u10, 1.75 ether, 1 wei);
        assertEq(nft.ownerOf(t), U2);
    }

    // 3) 파생, split 있음(정상) — upstreamBps 30%
    function test_Derivative_WithSplit_Primary_Secondary() public {
        // 부모 A (split 없음)
        nft.createOriginalWork(3, A,address(0));
        uint256[] memory aIds = nft.mintEditionBatch(A, 3, 1);
        uint256 parent = aIds[0];

        // 파생 B
        address sB = nft.createDerivativeWork(parent, 3001, B, 3000);
        uint256[] memory bIds = nft.mintDerivativeEditionBatch(B, 3001, parent, 1);
        uint256 t = bIds[0];

        _approveAndList(B, t, P1, true);

        uint256 fee0 = feeVault.balance;
        uint256 a0 = A.balance; uint256 b0 = B.balance;

        vm.prank(U1);
        market.buy{value:P1}(address(nft), t);

        assertEq(feeVault.balance - fee0, 0.025 ether);
        // net=0.975 → A 30%(0.2925), B 70%(0.6825)
        assertApproxEqAbs(A.balance - a0, 0.975 ether * 30 / 100, 2 wei);
        assertApproxEqAbs(B.balance - b0, 0.975 ether * 70 / 100, 2 wei);
        assertEq(nft.ownerOf(t), U1);

        _approveAndList(U1, t, P2, false);

        uint256 fee1 = feeVault.balance; uint256 u10 = U1.balance;
        a0 = A.balance; b0 = B.balance;

        vm.prank(U2);
        market.buy{value:P2}(address(nft), t);

        assertEq(feeVault.balance - fee1, 0.05 ether);
        // 로열티 0.2 → A 0.06, B 0.14
        assertApproxEqAbs(A.balance - a0, 0.06 ether, 2 wei);
        assertApproxEqAbs(B.balance - b0, 0.14 ether, 2 wei);
        // 재판매자
        assertApproxEqAbs(U1.balance - u10, 1.75 ether, 1 wei);
        assertEq(nft.ownerOf(t), U2);
    }

    // 4) 파생, split 없음(폴백) — childWork를 split=0으로 만들고 parentOf만 연결
    function test_Derivative_NoSplit_Primary_Secondary() public {
        nft.createOriginalWork(4, A, address(0));
        uint256[] memory aIds = nft.mintEditionBatch(A, 4, 1);
        uint256 parent = aIds[0];

        nft.createOriginalWork(4001, B, address(0)); // childWork split=0
        uint256[] memory bIds = nft.mintDerivativeEditionBatch(B, 4001, parent, 1);
        uint256 t = bIds[0];
        assertEq(nft.splitOf(t), address(0));

        _approveAndList(B, t, P1, true);

        uint256 fee0 = feeVault.balance; uint256 b0 = B.balance;

        vm.prank(U1);
        market.buy{value:P1}(address(nft), t);

        assertEq(feeVault.balance - fee0, 0.025 ether);
        assertApproxEqAbs(B.balance - b0, 0.975 ether, 1 wei); // 전액 B
        assertEq(nft.ownerOf(t), U1);

        _approveAndList(U1, t, P2, false);

        uint256 fee1 = feeVault.balance; uint256 u10 = U1.balance; b0 = B.balance;

        vm.prank(U2);
        market.buy{value:P2}(address(nft), t);

        assertEq(feeVault.balance - fee1, 0.05 ether);
        // 로열티 0.2 전액 B
        assertApproxEqAbs(B.balance - b0, 0.2 ether, 1 wei);
        assertApproxEqAbs(U1.balance - u10, 1.75 ether, 1 wei);
        assertEq(nft.ownerOf(t), U2);
    }

    // 실패/운영 파라미터
    function test_List_WithoutApproval_Revert() public {
        nft.createOriginalWork(9, A, address(0));
        nft.mintEditionBatch(A, 9, 1);
        vm.prank(A);
        vm.expectRevert(bytes("APPROVAL_REQUIRED"));
        market.list(address(nft), 1, P1, true);
    }

    // 이미 1차 판매 완료된 토큰 다시 1차 판매로 등록 불가 확인
    function test_Primary_Double_Revert() public {
        nft.createOriginalWork(8, A, address(0));
        uint256[] memory ids = nft.mintEditionBatch(S, 8, 1);
        uint256 t = ids[0];

        _approveAndList(S, t, P1, true);
        vm.prank(U1);
        market.buy{value:P1}(address(nft), t);

        vm.startPrank(U1);
        nft.setApprovalForAll(address(market), true);
        vm.expectRevert(bytes("PRIMARY_DONE"));
        market.list(address(nft), t, P1, true);
        vm.stopPrank();
    }

    function test_Admin_Parameters_And_Pause() public {
        // setFeeBps
        market.setFeeBps(500); // 5%
        // setRoyaltyBps
        market.setRoyaltyBps(1500); // 15%
        // setPaused
        market.setPaused(true);

        nft.createOriginalWork(7, A, address(0));
        nft.mintEditionBatch(A, 7, 1);
        vm.startPrank(A);
        nft.setApprovalForAll(address(market), true);
        vm.expectRevert(bytes("PAUSED"));
        market.list(address(nft), 1, P1, true);
        vm.stopPrank();

        market.setPaused(false);
        vm.prank(A);
        market.list(address(nft), 1, P1, true); // now ok
    }
}
