// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract VideoNFT is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    struct Video {
        uint256 videoId;         // 외부 DB의 영상 ID
        string nftName;          // NFT 이름
        string nftSymbol;        // NFT 심볼
        address creatorAddress;  // 크리에이터 지갑 주소
        uint256 totalSupply;     // NFT 총 발행 개수
        uint256 price;           // NFT 1개 가격
    }

    Counters.Counter private _tokenIdCounter;

    mapping(uint256 => Video) public videos;            // videoId -> Video
    mapping(uint256 => uint256) public tokenToVideo;    // tokenId -> videoId
    mapping(uint256 => bool) public videoExists;        // 중복 videoId 방지

    address public trustedOperator;

    event VideoNFTMinted(
        uint256 indexed videoId,
        address indexed creatorAddress,
        uint256 totalSupply,
        string name,
        string symbol,
        uint256 price
    );

    constructor(string memory name, string memory symbol, address _trustedOperator)
        ERC721(name, symbol)
    {
        trustedOperator = _trustedOperator;
    }

    function setTrustedOperator(address _operator) external onlyOwner {
        trustedOperator = _operator;
    }

    function mintVideoNFT(
        uint256 videoId,
        string memory nftName,
        string memory nftSymbol,
        uint256 totalSupply,
        uint256 price,
        address creatorAddress
    ) external {
        require(!videoExists[videoId], "Video ID already used");
        require(totalSupply > 0, "Total supply must be greater than 0");
        require(creatorAddress != address(0), "Invalid creator address");

        videos[videoId] = Video({
            videoId: videoId,
            nftName: nftName,
            nftSymbol: nftSymbol,
            creatorAddress: creatorAddress,
            totalSupply: totalSupply,
            price: price
        });

        videoExists[videoId] = true;

        for (uint256 i = 0; i < totalSupply; i++) {
            _tokenIdCounter.increment();
            uint256 tokenId = _tokenIdCounter.current();

            _mint(creatorAddress, tokenId);
            tokenToVideo[tokenId] = videoId;

            // ✅ 서버에 자동 approve
            _approve(trustedOperator, tokenId);
        }

        emit VideoNFTMinted(videoId, creatorAddress, totalSupply, nftName, nftSymbol, price);
    }

    // 🎯 영상 ID로 영상 관련 NFT 정보 조회
    function getVideoInfo(uint256 videoId) external view returns (
        string memory nftName,
        string memory nftSymbol,
        address creatorAddress,
        uint256 totalSupply,
        uint256 price
    ) {
        Video memory video = videos[videoId];
        return (
            video.nftName,
            video.nftSymbol,
            video.creatorAddress,
            video.totalSupply,
            video.price
        );
    }

    // 🎯 NFT tokenId로 어떤 영상(videoId)에 속하는지 조회
    function getVideoIdOfToken(uint256 tokenId) external view returns (uint256) {
        return tokenToVideo[tokenId];
    }

    
}
