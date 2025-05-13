const VideoNFT = artifacts.require("VideoNFT");
const VideoNFTMarketplace = artifacts.require("VideoNFTMarketplace");

module.exports = async function (deployer, network, accounts) {
  // 🔧 1. 설정값
  const nftName = "TokenUs VideoNFT";
  const nftSymbol = "TVN";
  const backendAddress = "0xbf39e8aBCE9073E902E919cA3c4923560E496Ee4"; // 👈 백엔드 지갑 주소로 바꿔줘!

  // 🔧 2. VideoNFT 배포 (임시 trustedOperator = 0x0)
  await deployer.deploy(VideoNFT, nftName, nftSymbol, "0x0000000000000000000000000000000000000000");
  const videoNFT = await VideoNFT.deployed();

  // 🔧 3. Marketplace 배포
  await deployer.deploy(VideoNFTMarketplace, videoNFT.address);
  const marketplace = await VideoNFTMarketplace.deployed();

  // 🔧 4. VideoNFT의 trustedOperator를 Marketplace로 설정
  await videoNFT.setTrustedOperator(marketplace.address);

  // 🔧 5. Marketplace에 백엔드 지갑 주소 등록
  await marketplace.approveOperator(backendAddress);

  console.log("✅ VideoNFT deployed to:", videoNFT.address);
  console.log("✅ VideoNFTMarketplace deployed to:", marketplace.address);
  console.log("✅ Backend address approved in Marketplace:", backendAddress);
};
