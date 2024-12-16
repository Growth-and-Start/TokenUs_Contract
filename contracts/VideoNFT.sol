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
        uint256 totalSupply; // 발행할 NFT 총 수량
        string name; // NFT 이름
        string symbol; // NFT 심볼
    }

    Counters.Counter private _videoIdCounter;
    Counters.Counter private _tokenIdCounter;

    mapping(uint256 => Video) public videos; // videoId -> Video
    mapping(uint256 => uint256) public tokenToVideo; // tokenId -> videoId

    constructor() ERC721("", "") {}

    event VideoNFTMinted(
        uint256 indexed videoId,
        address indexed creator,
        uint256 totalSupply,
        string NFTname,
        string NFTsymbol
    );

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
}
