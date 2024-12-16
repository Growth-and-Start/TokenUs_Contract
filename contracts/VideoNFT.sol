// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract VideoNFT is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    struct Video {
        uint256 id;
        string metadataURI; // AWS S3에 저장된 영상 메타데이터 URI
        address creator; // 크리에이터 주소
        uint256 totalSupply; // 발행된 NFT 총 수량
        string name; // NFT 이름
        string symbol; // NFT 심볼
    }

    struct VideoRevenue {
        uint256 totalRevenue; // 영상의 총 수익
        mapping(address => uint256) shares; // 각 소유자의 수익 배분
    }

    Counters.Counter private _videoIdCounter;
    Counters.Counter private _tokenIdCounter;

    mapping(uint256 => Video) public videos; // videoId -> Video
    mapping(uint256 => uint256) public tokenToVideo; // tokenId -> videoId
    mapping(uint256 => VideoRevenue) private videoRevenues; // videoId -> VideoRevenue

    uint256 public constant ROYALTY_PERCENTAGE = 5; // 고정된 로열티 비율 (5%)

    constructor() ERC721("", "") {}

    event VideoNFTMinted(
        uint256 indexed videoId,
        address indexed creator,
        uint256 totalSupply,
        string NFTname,
        string NFTsymbol
    );
    event TokenPurchased(uint256 indexed tokenId, address indexed buyer, uint256 price);
    event RevenueDistributed(uint256 indexed videoId, uint256 amount);

    // 영상 업로드 및 NFT 발행
    function mintVideoNFT(
        string memory metadataURI,
        uint256 totalSupply,
        string memory NFTname,
        string memory NFTsymbol
    ) external {
        require(totalSupply > 0, "Total supply must be greater than 0");
        require(bytes(NFTname).length > 0, "NFT name cannot be empty");
        require(bytes(NFTsymbol).length > 0, "NFT symbol cannot be empty");

        _videoIdCounter.increment();
        uint256 videoId = _videoIdCounter.current();

        videos[videoId] = Video({
            id: videoId,
            metadataURI: metadataURI,
            creator: msg.sender,
            totalSupply: totalSupply,
            name: NFTname,
            symbol: NFTsymbol
        });

        for (uint256 i = 0; i < totalSupply; i++) {
            _tokenIdCounter.increment();
            uint256 tokenId = _tokenIdCounter.current();

            _safeMint(msg.sender, tokenId);
            tokenToVideo[tokenId] = videoId;
        }

        emit VideoNFTMinted(videoId, msg.sender, totalSupply, NFTname, NFTsymbol);
    }

    // // NFT 구매 및 로열티 처리
    // function purchaseToken(uint256 tokenId) external payable {
    //     require(_exists(tokenId), "Token does not exist");
    //     address owner = ownerOf(tokenId);
    //     require(owner != msg.sender, "Cannot purchase your own token");

    //     uint256 videoId = tokenToVideo[tokenId];
    //     Video memory video = videos[videoId];

    //     uint256 price = msg.value;
    //     require(price > 0, "Price must be greater than zero");

    //     uint256 royalty = (price * ROYALTY_PERCENTAGE) / 100;
    //     uint256 sellerShare = price - royalty;

    //     // 로열티를 크리에이터에게 전송
    //     payable(video.creator).transfer(royalty);

    //     // 나머지 금액을 기존 소유자에게 전송
    //     payable(owner).transfer(sellerShare);

    //     // 토큰 소유권 이전
    //     _transfer(owner, msg.sender, tokenId);

    //     // 수익 기록 업데이트
    //     videoRevenues[videoId].totalRevenue += price;
    //     videoRevenues[videoId].shares[msg.sender] += price;

    //     emit TokenPurchased(tokenId, msg.sender, price);
    // }

    // // 수익 분배
    // function distributeRevenue(uint256 videoId) external {
    //     Video storage video = videos[videoId];
    //     require(video.creator == msg.sender, "Not the creator of the video");

    //     VideoRevenue storage revenue = videoRevenues[videoId];
    //     require(revenue.totalRevenue > 0, "No revenue to distribute");

    //     uint256 totalRevenue = revenue.totalRevenue;
    //     revenue.totalRevenue = 0;

    //     uint256 totalTokens = video.totalSupply;
    //     uint256 perTokenRevenue = totalRevenue / totalTokens;

    //     for (uint256 i = 0; i < totalTokens; i++) {
    //         uint256 tokenId = tokenByIndex(i);
    //         address owner = ownerOf(tokenId);

    //         uint256 share = perTokenRevenue;
    //         if (share > 0) {
    //             payable(owner).transfer(share);
    //             revenue.shares[owner] -= share;
    //         }
    //     }

    //     emit RevenueDistributed(videoId, totalRevenue);
    // }

    // // NFT 이름 조회
    // function name() public view override returns (string memory) {
    //     if (balanceOf(msg.sender) > 0) {
    //         uint256 videoId = tokenToVideo[tokenOfOwnerByIndex(msg.sender, 0)];
    //         return videos[videoId].name;
    //     }
    //     return "VideoNFTPlatform";
    // }

    // // NFT 심볼 조회
    // function symbol() public view override returns (string memory) {
    //     if (balanceOf(msg.sender) > 0) {
    //         uint256 videoId = tokenToVideo[tokenOfOwnerByIndex(msg.sender, 0)];
    //         return videos[videoId].symbol;
    //     }
    //     return "VNFT";
    // }

    // // 영상 메타데이터 URI 조회
    // function getVideoMetadataURI(uint256 videoId) external view returns (string memory) {
    //     return videos[videoId].metadataURI;
    // }

    // // 영상의 크리에이터 조회
    // function getVideoCreator(uint256 videoId) external view returns (address) {
    //     return videos[videoId].creator;
    // }

    // // 영상의 NFT 총 발행량 조회
    // function getVideoTotalSupply(uint256 videoId) external view returns (uint256) {
    //     return videos[videoId].totalSupply;
    // }

    // // 특정 토큰이 어떤 영상에 속해있는지 조회
    // function getTokenVideoId(uint256 tokenId) external view returns (uint256) {
    //     return tokenToVideo[tokenId];
    // }
}
