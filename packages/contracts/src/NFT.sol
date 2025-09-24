// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "../lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import "./CascadingSplit.sol";

/// @title NFT (Works + Editions + Derivative Batch)
/// @notice
///  - 원본/파생 모두 "작품(Work)" 단위로 관리, 에디션 여러 장 민팅 가능.
///  - 파생 작품 생성 시 작품 전용 Split 1개 생성 → 해당 작품 에디션이 공유.
///  - 각 파생 에디션은 parentOf[tokenId]=부모 tokenId로 계보 기록.
contract NFT is ERC721 {
    using Strings for uint256;

    address public admin; modifier onlyAdmin(){ require(msg.sender==admin,"NOT_ADMIN"); _; }

    struct Work { address creator; address split; string baseURI; bool exists; }
    mapping(uint256 => Work) public works;     // workId → Work
    mapping(uint256 => uint256) public workOf; // tokenId → workId

    mapping(uint256 => address) public creatorOf; // tokenId → creator
    mapping(uint256 => uint256) public parentOf;  // tokenId → parent tokenId
    mapping(uint256 => address) public splitOf;   // tokenId → split addr

    uint256 private _nextTokenId;

    event SplitCreated(address split, address upstream, address child, uint16 upstreamBps);
    event WorkCreated(uint256 indexed workId, address creator, address split, string baseURI);

    constructor() ERC721("VideoNFT","vNFT") { admin=msg.sender; _nextTokenId = 1; }

    // ── 원본(루트) 작품 등록
    function createOriginalWork(
        uint256 workId,
        address creator,
        string  calldata baseURI,
        address splitAddr
    ) external onlyAdmin {
        require(!works[workId].exists, "WORK_EXISTS");
        works[workId] = Work({ creator:creator, split:splitAddr, baseURI:baseURI, exists:true });
        emit WorkCreated(workId, creator, splitAddr, baseURI);
    }

    function setWorkBaseURI(uint256 workId, string calldata baseURI) external onlyAdmin {
        require(works[workId].exists,"NO_WORK"); works[workId].baseURI=baseURI;
    }
    function setWorkSplit(uint256 workId, address splitAddr) external onlyAdmin {
        require(works[workId].exists,"NO_WORK"); works[workId].split=splitAddr;
    }

    // ── (공통) 작품 에디션 배치 민팅
    function mintEditionBatch(address to, uint256 workId, uint256 amount)
        public onlyAdmin returns (uint256[] memory ids)
    {
        require(works[workId].exists,"NO_WORK"); require(amount>0,"AMOUNT_ZERO");
        ids = new uint256[](amount);
        for(uint256 i=0;i<amount;i++){
            uint256 id=_nextTokenId++; 
            _safeMint(to,id);
            workOf[id]=workId;
            creatorOf[id]=works[workId].creator;
            splitOf[id]=works[workId].split; // 작품 Split 공유(없으면 0)
            ids[i]=id;
        }
    }

    // ── 파생 작품 생성 + 작품 전용 Split 1개 생성
    function createDerivativeWorkWithSplit(
        uint256 parentTokenId,
        uint256 childWorkId,
        address childCreator,
        string  calldata baseURI,
        uint16  upstreamBps
    ) external onlyAdmin returns (address splitAddr) {
        require(_ownerOf(parentTokenId)!=address(0),"NO_PARENT_TOKEN");
        require(!works[childWorkId].exists,"WORK_EXISTS");
        require(childCreator!=address(0),"CREATOR=0");
        require(upstreamBps<=10000,"BPS>10000");

        address upstream = splitOf[parentTokenId]!=address(0) ? splitOf[parentTokenId] : creatorOf[parentTokenId];
        splitAddr = address(new CascadingSplit(upstream, childCreator, upstreamBps));
        emit SplitCreated(splitAddr, upstream, childCreator, upstreamBps);

        works[childWorkId] = Work({ creator:childCreator, split:splitAddr, baseURI:baseURI, exists:true });
        emit WorkCreated(childWorkId, childCreator, splitAddr, baseURI);
    }

    // ── 파생 작품 에디션 배치 민팅 + 계보(parent) 연결
    function mintDerivativeEditionBatch(
        address to,
        uint256 childWorkId,
        uint256 parentTokenId,
        uint256 amount
    ) external onlyAdmin returns (uint256[] memory ids) {
        require(works[childWorkId].exists,"NO_CHILD_WORK");
        require(_ownerOf(parentTokenId)!=address(0),"NO_PARENT_TOKEN");
        ids = mintEditionBatch(to, childWorkId, amount);
        for(uint256 i=0;i<ids.length;i++){ parentOf[ids[i]] = parentTokenId; }
    }

    // 메타데이터
    function tokenURI(uint256 id) public view override returns (string memory){
        _requireOwned(id);
        string memory base = works[workOf[id]].baseURI;
        return bytes(base).length==0 ? "" : string(abi.encodePacked(base,"/",id.toString(),".json"));
    }
}
