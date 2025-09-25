// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/NFT.sol";
import "../src/CascadingSplit.sol";

contract NFTTest is Test {
    NFT nft;
    address admin = address(this);
    address creatorA = address(0xA1);
    address creatorB = address(0xB1);

    function setUp() public { nft = new NFT(); }

    function test_CreateOriginal_And_MintBatch() public {
        nft.createOriginalWork(1, creatorA, address(0));
        uint256[] memory ids = nft.mintEditionBatch(creatorA, 1, 3);
        assertEq(ids.length,3);
        for(uint256 i;i<ids.length;i++){
            assertEq(nft.ownerOf(ids[i]), creatorA);
            assertEq(nft.workOf(ids[i]), 1);
            assertEq(nft.creatorOf(ids[i]), creatorA);
            assertEq(nft.splitOf(ids[i]), address(0));
        }
       
    }

    // Split 변경 시 이후에 민팅되는 에디션만 새 Split을 복사하는지 확인 (기존 토큰은 Split 그대로 유지)
    function test_SetWorkSplit_Applies_To_Future_Mints_Only() public {
        nft.createOriginalWork(2, creatorA, address(0));
        uint256[] memory a1 = nft.mintEditionBatch(creatorA, 2, 1);
        assertEq(nft.splitOf(a1[0]), address(0));

        // 새 split 지정
        CascadingSplit s = new CascadingSplit(address(0), creatorA, 0);
        nft.setWorkSplit(2, address(s));

        // 이후 민팅부터 split 복사
        uint256[] memory a2 = nft.mintEditionBatch(creatorA, 2, 1);
        assertEq(nft.splitOf(a2[0]), address(s));
        // 기존 토큰은 그대로
        assertEq(nft.splitOf(a1[0]), address(0));
    }

    function test_CreateDerivativeWork_WithSplit_And_Mint() public {
        nft.createOriginalWork(10, creatorA, address(0));
        uint256[] memory base = nft.mintEditionBatch(creatorA, 10, 1);
        uint256 parentId = base[0];

        address split = nft.createDerivativeWork(parentId, 1001, creatorB, 3000);
        assertTrue(split != address(0));

        uint256[] memory child = nft.mintDerivativeEditionBatch(creatorB, 1001, parentId, 2);
        for(uint256 i;i<child.length;i++){
            assertEq(nft.ownerOf(child[i]), creatorB);
            assertEq(nft.parentOf(child[i]), parentId);
            assertEq(nft.workOf(child[i]), 1001);
            assertEq(nft.splitOf(child[i]), split);
        }
    }

    // 존재하지 않는 부모 토큰으로 파생 작품 생성 시 revert
    function test_Revert_NoParent_OnDerivativeWork() public {
        vm.expectRevert(bytes("NO_PARENT_TOKEN"));
        nft.createDerivativeWork(999999, 7777, creatorB, 1000);
    }
}
