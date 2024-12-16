const VideoNFT = artifacts.require("VideoNFT");
const VideoNFTMarketplace = artifacts.require("VideoNFTMarketplace");

contract("VideoNFTMarketplace", (accounts) => {
  let videoNFT;
  let marketplace;

  before(async () => {
    // VideoNFT 및 VideoNFTMarketplace 컨트랙트 배포
    videoNFT = await VideoNFT.new();
    marketplace = await VideoNFTMarketplace.new(videoNFT.address);
  });

  it("should allow purchasing an NFT", async () => {
    // 1. NFT를 발행
    await videoNFT.mintVideoNFT("test-metadata-uri", 1, "TestNFT", "TST", { from: accounts[0] });
  
    // 2. 판매자가 VideoNFTMarketplace 컨트랙트에 전송 권한을 승인
    await videoNFT.approve(marketplace.address, 1, { from: accounts[0] }); // accounts[0]는 NFT 소유자
  
    // 3. NFT를 판매 목록에 등록
    await marketplace.listNFT(1, web3.utils.toWei("1", "ether"), { from: accounts[0] });
  
    // 4. 구매자가 NFT를 구매
    await marketplace.purchaseNFT(1, { from: accounts[1], value: web3.utils.toWei("1", "ether") });
  
    // 5. 구매자가 소유자인지 확인
    const newOwner = await videoNFT.ownerOf(1);
    assert.equal(newOwner, accounts[1], "NFT ownership should be transferred");
  });  
});
