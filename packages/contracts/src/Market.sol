// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title Market (NFT 마켓플레이스)
/// @notice
///  - 1차(초도) 판매: 수수료 제외 "전액"을 Split.deposit()으로 송금 → 재귀 분배.
///  - 2차(재판매): 수수료 제외 "로열티 r%"만 Split.deposit(), 나머지는 판매자.
/// @dev
///  - 토큰별 1차 판매 완료 여부(primarySold)로 isPrimary 오남용 방지.
///  - 네이티브(ETH/MATIC) 결제만 지원(ERC-20은 별도 함수 확장 필요).
///  - 재진입 방지(nonReentrant)와 승인 검사(APPROVAL_REQUIRED) 포함.

interface INFT {
    function splitOf(uint256 id) external view returns (address);
    function creatorOf(uint256 id) external view returns (address);
    function parentOf(uint256 id) external view returns (uint256);
}

contract Market is ReentrancyGuard {
    /// @dev 단일 토큰의 판매 등록 정보
    struct Listing {
        address seller;   // 판매자(현재 소유자)
        uint256 price;    // 판매가(네이티브 단위)
        bool    isPrimary;// 1차(초도) 판매 여부
    }

    /// @dev listings[nft주소][tokenId] → Listing
    mapping(address => mapping(uint256 => Listing)) public listings;

    /// @dev primarySold[nft주소][tokenId] → true면 1차 판매 완료(재등록 불가)
    mapping(address => mapping(uint256 => bool)) public primarySold;

    // ===== 플랫폼 파라미터 =====
    uint96 public constant MAX_BPS = 10000; // 기준분모(=10000bps=100%)
    uint96 public feeBps = 250;            // 플랫폼 수수료 2.5% (기본값)
    uint96 public resaleRoyaltyBps = 1000; // 재판매 로열티 10% (기본값)
    address public feeVault;               // 수수료 수령 지갑
    address public admin;                  // 운영 권한자
    bool    public paused;                 // 마켓 정지 플래그

    // ===== 접근제어/상태 체크 =====
    modifier onlyAdmin() { require(msg.sender == admin, "NOT_ADMIN"); _; }
    modifier notPaused() { require(!paused, "PAUSED"); _; }

    // ===== 이벤트 =====
    event Listed(
        address indexed nft,
        uint256 indexed id,
        address seller,
        uint256 price,
        bool primary
    );
    event Cancelled(address indexed nft, uint256 indexed id);
    event Bought(
        address indexed nft,
        uint256 indexed id,
        address seller,
        address buyer,
        uint256 price,
        bool primary
    );

    /// @param _feeVault 플랫폼 수수료를 받을 지갑 주소
    constructor(address _feeVault) {
        feeVault = _feeVault;
        admin = msg.sender;
    }

    // ------------------------------------------------------------------------
    // 리스트(판매 등록)
    // ------------------------------------------------------------------------

    /// @notice 토큰을 고정가로 판매 등록(사전 승인 필요).
    /// @dev
    ///  - 소유자 검증: IERC721(nft).ownerOf(id) == msg.sender
    ///  - 승인 검증: getApproved(id) == this || isApprovedForAll(seller, this)
    ///  - 1차 판매 등록 시 primarySold가 false여야 함.
    /// @param nft   ERC-721 컨트랙트 주소
    /// @param id    토큰 ID
    /// @param price 판매가(네이티브)
    /// @param isPrimary 1차(초도) 판매인지 여부
    function list(
        address nft,
        uint256 id,
        uint256 price,
        bool isPrimary
    ) external notPaused {
        IERC721 _n = IERC721(nft);

        // 1) 판매자=소유자 검증
        require(_n.ownerOf(id) == msg.sender, "NOT_OWNER");

        // 2) 마켓 컨트랙트에 이전 권한(승인) 부여 여부 확인
        bool ok = (_n.getApproved(id) == address(this)) ||
                  (_n.isApprovedForAll(msg.sender, address(this)));
        require(ok, "APPROVAL_REQUIRED");

        // 3) 1차 판매는 중복 등록 불가
        if (isPrimary) require(!primarySold[nft][id], "PRIMARY_DONE");

        // 4) 등록
        listings[nft][id] = Listing(msg.sender, price, isPrimary);
        emit Listed(nft, id, msg.sender, price, isPrimary);
    }

    /// @notice 본인이 올린 판매 등록을 취소
    function cancel(address nft, uint256 id) external notPaused {
        Listing memory L = listings[nft][id];
        require(L.seller == msg.sender, "NOT_SELLER");

        delete listings[nft][id];
        emit Cancelled(nft, id);
    }

    // ------------------------------------------------------------------------
    // 구매
    // ------------------------------------------------------------------------

    /// @notice 등록된 토큰을 구매(네이티브 결제).
    /// @dev 재진입 방지(nonReentrant). 결제→분배→이전→정리 순서.
    ///      - 1차: (가격-수수료) "전액"을 Split.deposit()으로 송금 → 조상/자식 재귀 분배
    ///      - 2차: (가격-수수료) 중 "로열티"만 Split.deposit(), 나머지는 판매자 귀속
    /// @param nft ERC-721 컨트랙트 주소
    /// @param id  토큰 ID
    function buy(address nft, uint256 id) external payable notPaused nonReentrant {
    Listing memory L = listings[nft][id];
    require(L.price > 0, "NO_LIST");
    require(msg.value == L.price, "BAD_PRICE");

    // 플랫폼 수수료
    uint256 fee = (msg.value * feeBps) / MAX_BPS;
    _pay(feeVault, fee);

    uint256 net   = msg.value - fee;         // 분배/판매자 정산 전 순액

    address split = INFT(nft).splitOf(id);
    address creator = INFT(nft).creatorOf(id);
    bool isOriginal = (INFT(nft).parentOf(id) == 0);

    if (isOriginal) {
        // ── 원본 토큰
        if (L.isPrimary) {
            require(!primarySold[nft][id], "PRIMARY_DONE");
            if (split != address(0)) {
                // 원본에도 작품 단위 split이 설정되어 있다면 전액 분배
                (bool ok,) = split.call{value: net}(abi.encodeWithSignature("deposit()"));
                require(ok, "split fail");
            } else {
                // split이 없으면 전액 판매자(또는 creator)에게 직지급
                _pay(L.seller, net);
            }
            primarySold[nft][id] = true;
        } else {
            // 2차: 로열티만 창작자 측으로
            uint256 royalty = (msg.value * resaleRoyaltyBps) / MAX_BPS;
            if (royalty > net) royalty = net;

            if (split != address(0)) {
                (bool ok,) = split.call{value: royalty}(abi.encodeWithSignature("deposit()"));
                require(ok, "split fail");
            } else {
                // split이 없으면 원작자 EOA로 직접 지급
                _pay(creator, royalty);
            }
            _pay(L.seller, net - royalty);
        }
    } else {
        // ── 파생 토큰: 원칙적으로 split 존재(재귀 분배) 가정
        if (L.isPrimary) {
            require(!primarySold[nft][id], "PRIMARY_DONE");
            if (split != address(0)) {
                (bool ok,) = split.call{value: net}(abi.encodeWithSignature("deposit()"));
                require(ok, "split fail");
            } else {
                // 예외 폴백: split이 없다면 자식 창작자에게 직지급
                _pay(creator, net);
            }
            primarySold[nft][id] = true;
        } else {
            uint256 royalty = (msg.value * resaleRoyaltyBps) / MAX_BPS;
            if (royalty > net) royalty = net;

            if (split != address(0)) {
                (bool ok,) = split.call{value: royalty}(abi.encodeWithSignature("deposit()"));
                require(ok, "split fail");
            } else {
                _pay(creator, royalty);
            }
            _pay(L.seller, net - royalty);
        }
    }

    // 소유권 이전(사전 approve 필요)
    IERC721(nft).safeTransferFrom(L.seller, msg.sender, id);

    // 정리
    delete listings[nft][id];
    emit Bought(nft, id, L.seller, msg.sender, msg.value, L.isPrimary);
}


    // ------------------------------------------------------------------------
    // 내부 유틸 & 운영 파라미터
    // ------------------------------------------------------------------------

    /// @dev 네이티브 전송 헬퍼(성공 여부 체크)
    function _pay(address to, uint256 amt) internal {
        (bool ok, ) = payable(to).call{value: amt}("");
        require(ok, "PAY_FAIL");
    }

    /// @notice 플랫폼 수수료(BPS) 설정(0~10000)
    function setFeeBps(uint96 v) external onlyAdmin {
        require(v <= MAX_BPS, ">MAX");
        feeBps = v;
    }

    /// @notice 재판매 로열티(BPS) 설정(0~10000)
    function setRoyaltyBps(uint96 v) external onlyAdmin {
        require(v <= MAX_BPS, ">MAX");
        resaleRoyaltyBps = v;
    }

    /// @notice 수수료 수령 지갑 변경
    function setFeeVault(address v) external onlyAdmin {
        feeVault = v;
    }

    /// @notice 마켓 일시정지/해제
    function setPaused(bool v) external onlyAdmin {
        paused = v;
    }
}
