// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./VideoNFT.sol"; // VideoNFT 컨트랙트를 임포트

contract VideoNFTMarketplace is Ownable {
    // 판매 등록 정보를 담는 구조체
    struct Listing {
        uint256 tokenId; // 판매 중인 NFT의 토큰 ID
        address seller; // 판매자 주소
        uint256 price; // NFT 판매 가격 (wei 단위)
        bool isListed; // 현재 판매 중인지 여부
    }

    VideoNFT private videoNFT; // VideoNFT 컨트랙트의 인스턴스
    mapping(uint256 => Listing) public listings; // tokenId를 키로 사용하여 Listing 구조체를 저장

    // 이벤트 정의
    event NFTListed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event NFTDelisted(uint256 indexed tokenId, address indexed seller);
    event NFTPurchased(uint256 indexed tokenId, address indexed buyer, uint256 price);

    // 생성자: VideoNFT 컨트랙트 주소r로 초기화
    constructor(address _videoNFTAddress) {
        videoNFT = VideoNFT(_videoNFTAddress);
    }


    // NFT 판매 등록 함수
    function listNFT(uint256 tokenId, uint256 price) external {
        address nftOwner = videoNFT.ownerOf(tokenId);
        address trustedOperator = videoNFT.trustedOperator();

        // ✅ 인증 조건: 직접 소유자이거나, 서버(trustedOperator)이면서 사전 승인받았을 때만 허용
        bool isOwner = msg.sender == nftOwner;
        bool isAuthorizedOperator = (
            msg.sender == trustedOperator &&
            (videoNFT.getApproved(tokenId) == trustedOperator ||
             videoNFT.isApprovedForAll(nftOwner, trustedOperator))
        );

        require(isOwner || isAuthorizedOperator, "Not authorized to list this NFT");

        listings[tokenId] = Listing({
            tokenId: tokenId,
            seller: nftOwner, // ✅ 실제 소유자를 seller로 저장
            price: price,
            isListed: true
        });

        emit NFTListed(tokenId, nftOwner, price);
    }


    // NFT 판매 등록 취소 함수
    function delistNFT(uint256 tokenId) external {

        address nftOwner = videoNFT.ownerOf(tokenId);
        address trustedOperator = videoNFT.trustedOperator();

        Listing memory listing = listings[tokenId]; // 해당 토큰의 판매 정보를 가져옴
        require(listing.isListed, "NFT is not listed"); // NFT가 판매 등록되어 있는지 확인
        
        // ✅ 인증 조건: 직접 소유자이거나, 서버(trustedOperator)이면서 사전 승인받았을 때만 허용
        bool isOwner = msg.sender == nftOwner;
        bool isAuthorizedOperator = (
            msg.sender == trustedOperator &&
            (videoNFT.getApproved(tokenId) == trustedOperator ||
             videoNFT.isApprovedForAll(nftOwner, trustedOperator))
        );

        require(isOwner || isAuthorizedOperator, "Not authorized to delist this NFT");

        delete listings[tokenId]; // 판매 정보 삭제

        emit NFTDelisted(tokenId, msg.sender); // 이벤트 발생
    }

    // NFT 구매 함수
    function purchaseNFT(uint256 tokenId) external payable {
        Listing memory listing = listings[tokenId]; // 해당 토큰의 판매 정보를 가져옴
        require(listing.isListed, "NFT is not listed for sale"); // NFT가 판매 등록되어 있는지 확인
        require(msg.value >= listing.price, "Insufficient payment"); // 구매 금액이 판매 가격 이상인지 확인

        // 판매자에게 금액 전송
        payable(listing.seller).transfer(listing.price);

        // NFT를 구매자에게 전송
        videoNFT.safeTransferFrom(listing.seller, msg.sender, tokenId);

        // 판매 정보 삭제
        delete listings[tokenId];

        emit NFTPurchased(tokenId, msg.sender, listing.price); // 이벤트 발생
    }

    function getListedNFTs() external view returns(
        uint256[] memory tokenIds,
        address[] memory sellers,
        uint256[] memory prices
    ){
        uint256 totalTokens = videoNFT.totalSupply(); // 발행된 전체 토큰 수
        uint256 listedCount = 0;

        // 판매 중인 NFT의 개수 계산
        for (uint256 i = 0; i < totalTokens; i++) {
            uint256 tokenId = videoNFT.tokenByIndex(i);
            if (listings[tokenId].isListed) {
                listedCount++;
            }
        }

        // 개별 배열 생성
        tokenIds = new uint256[](listedCount);
        sellers = new address[](listedCount);
        prices = new uint256[](listedCount);

        uint256 index = 0;

        // 판매 중인 NFT 데이터를 배열에 저장
        for (uint256 i = 1; i <= totalTokens; i++) {
            if (listings[i].isListed) {
                tokenIds[index] = listings[i].tokenId;
                sellers[index] = listings[i].seller;
                prices[index] = listings[i].price;
                index++;
            }
        }
        return (tokenIds, sellers, prices);
    }
}
