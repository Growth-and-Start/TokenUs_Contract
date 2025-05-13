// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./VideoNFT.sol";

contract VideoNFTMarketplace is Ownable {
    // 판매 등록 정보를 담는 구조체
    struct Listing {
        uint256 tokenId;
        address seller;
        uint256 price;
        bool isListed;
    }

    VideoNFT private videoNFT;
    mapping(uint256 => Listing) public listings;

    // ✅ 백엔드 서버와 같은 외부 지갑을 사전 승인하기 위한 매핑
    mapping(address => bool) public approvedOperators;

    // 이벤트 정의
    event NFTListed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event NFTDelisted(uint256 indexed tokenId, address indexed seller);
    event NFTPurchased(uint256 indexed tokenId, address indexed buyer, uint256 price);
    event OperatorApproved(address indexed operator, bool approved);

    // 생성자
    constructor(address _videoNFTAddress) {
        videoNFT = VideoNFT(_videoNFTAddress);
    }

    // ✅ 백엔드 지갑 주소 등 외부 operator 사전 승인 (owner만 가능)
    function approveOperator(address operator) external onlyOwner {
        approvedOperators[operator] = true;
        emit OperatorApproved(operator, true);
    }

    // ✅ NFT 판매 등록 함수
    function listNFT(uint256 tokenId, uint256 price) external {
        address nftOwner = videoNFT.ownerOf(tokenId);

        // 조건 1: 직접 소유자
        bool isOwner = msg.sender == nftOwner;

        // 조건 2: approvedOperator이고, Marketplace가 approve 받은 상태
        bool isAuthorizedOperator = (
            approvedOperators[msg.sender] &&
            (
                videoNFT.getApproved(tokenId) == address(this) ||
                videoNFT.isApprovedForAll(nftOwner, address(this))
            )
        );

        require(isOwner || isAuthorizedOperator, "Not authorized to list this NFT");

        listings[tokenId] = Listing({
            tokenId: tokenId,
            seller: nftOwner,
            price: price,
            isListed: true
        });

        emit NFTListed(tokenId, nftOwner, price);
    }

    // NFT 판매 등록 취소
    function delistNFT(uint256 tokenId) external {
        Listing memory listing = listings[tokenId];
        require(listing.isListed, "NFT is not listed");

        address nftOwner = videoNFT.ownerOf(tokenId);

        bool isOwner = msg.sender == nftOwner;
        bool isAuthorizedOperator = (
            approvedOperators[msg.sender] &&
            (
                videoNFT.getApproved(tokenId) == address(this) ||
                videoNFT.isApprovedForAll(nftOwner, address(this))
            )
        );

        require(isOwner || isAuthorizedOperator, "Not authorized to delist");

        delete listings[tokenId];

        emit NFTDelisted(tokenId, msg.sender);
    }

    // NFT 구매
    function purchaseNFT(uint256 tokenId) external payable {
    Listing memory listing = listings[tokenId];
    require(listing.isListed, "NFT is not listed for sale");
    require(msg.value >= listing.price, "Insufficient payment");

    address actualOwner = videoNFT.ownerOf(tokenId);
    require(actualOwner == listing.seller, "Listing seller is not current owner");

    require(
        videoNFT.getApproved(tokenId) == address(this) ||
        videoNFT.isApprovedForAll(actualOwner, address(this)),
        "Marketplace is not approved to transfer this NFT"
    );

    payable(listing.seller).transfer(listing.price);

    videoNFT.safeTransferFrom(listing.seller, msg.sender, tokenId);

    delete listings[tokenId];

    emit NFTPurchased(tokenId, msg.sender, listing.price);
}


    // 등록된 NFT 목록 반환
    function getListedNFTs() external view returns(
        uint256[] memory tokenIds,
        address[] memory sellers,
        uint256[] memory prices
    ){
        uint256 totalTokens = videoNFT.totalSupply();
        uint256 listedCount = 0;

        for (uint256 i = 0; i < totalTokens; i++) {
            uint256 tokenId = videoNFT.tokenByIndex(i);
            if (listings[tokenId].isListed) {
                listedCount++;
            }
        }

        tokenIds = new uint256[](listedCount);
        sellers = new address[](listedCount);
        prices = new uint256[](listedCount);

        uint256 index = 0;

        for (uint256 i = 0; i < totalTokens; i++) {
            uint256 tokenId = videoNFT.tokenByIndex(i);
            if (listings[tokenId].isListed) {
                tokenIds[index] = listings[tokenId].tokenId;
                sellers[index] = listings[tokenId].seller;
                prices[index] = listings[tokenId].price;
                index++;
            }
        }

        return (tokenIds, sellers, prices);
    }
}
