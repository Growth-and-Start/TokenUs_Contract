// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

/// @title Market (NFT 마켓플레이스)

interface IVideoNFT {
    function splitOf(uint256 id) external view returns (address);
}

contract Market is ReentrancyGuard {
    struct Listing { address seller; uint256 price; bool isPrimary; }
    mapping(address=>mapping(uint256=>Listing)) public listings;
    mapping(address=>mapping(uint256=>bool)) public primarySold;

    uint96 public constant MAX_BPS=10000;
    uint96 public feeBps=250; uint96 public resaleRoyaltyBps=1000;
    address public feeVault; address public admin; bool public paused;
    modifier onlyAdmin(){ require(msg.sender==admin,"NOT_ADMIN"); _; }
    modifier notPaused(){ require(!paused,"PAUSED"); _; }

    event Listed(address indexed nft, uint256 indexed id, address seller, uint256 price, bool primary);
    event Cancelled(address indexed nft, uint256 indexed id);
    event Bought(address indexed nft, uint256 indexed id, address seller, address buyer, uint256 price, bool primary);

    constructor(address _feeVault){ feeVault=_feeVault; admin=msg.sender; }

    function list(address nft, uint256 id, uint256 price, bool isPrimary) external notPaused {
        IERC721 _n = IERC721(nft);
        require(_n.ownerOf(id)==msg.sender,"NOT_OWNER");
        bool ok = (_n.getApproved(id)==address(this)) || (_n.isApprovedForAll(msg.sender,address(this)));
        require(ok,"APPROVAL_REQUIRED");
        if(isPrimary) require(!primarySold[nft][id],"PRIMARY_DONE");
        listings[nft][id]=Listing(msg.sender,price,isPrimary);
        emit Listed(nft,id,msg.sender,price,isPrimary);
    }

    function cancel(address nft, uint256 id) external notPaused {
        Listing memory L=listings[nft][id]; require(L.seller==msg.sender,"NOT_SELLER");
        delete listings[nft][id]; emit Cancelled(nft,id);
    }

    function buy(address nft, uint256 id) external payable notPaused nonReentrant {
        Listing memory L=listings[nft][id]; require(L.price>0,"NO_LIST"); require(msg.value==L.price,"BAD_PRICE");
        uint256 fee=(msg.value*feeBps)/MAX_BPS; _pay(feeVault,fee);
        uint256 net=msg.value-fee; address split=IVideoNFT(nft).splitOf(id);

        if(L.isPrimary){
            require(!primarySold[nft][id],"PRIMARY_DONE");
            (bool ok,) = split.call{value:net}(abi.encodeWithSignature("deposit()")); require(ok,"split fail");
            primarySold[nft][id]=true;
        } else {
            uint256 royalty=(msg.value*resaleRoyaltyBps)/MAX_BPS; if(royalty>net) royalty=net;
            (bool ok,) = split.call{value:royalty}(abi.encodeWithSignature("deposit()")); require(ok,"split fail");
            _pay(L.seller, net-royalty);
        }

        IERC721(nft).safeTransferFrom(L.seller, msg.sender, id);
        delete listings[nft][id];
        emit Bought(nft,id,L.seller,msg.sender,msg.value,L.isPrimary);
    }

    function _pay(address to, uint256 amt) internal { (bool ok,) = payable(to).call{value:amt}(""); require(ok,"PAY_FAIL"); }
    function setFeeBps(uint96 v) external onlyAdmin { require(v<=MAX_BPS,">MAX"); feeBps=v; }
    function setRoyaltyBps(uint96 v) external onlyAdmin { require(v<=MAX_BPS,">MAX"); resaleRoyaltyBps=v; }
    function setFeeVault(address v) external onlyAdmin { feeVault=v; }
    function setPaused(bool v) external onlyAdmin { paused=v; }
}
