const VideoNFT = artifacts.require("VideoNFT");
const VideoNFTMarketplace = artifacts.require("VideoNFTMarketplace");

module.exports = async function (deployer) {
  const name = "TokenUs VideoNFT";
  const symbol = "TVN";
  const trustedOperator = "0xbf39e8aBCE9073E902E919cA3c4923560E496Ee4"; // 서버 주소

  await deployer.deploy(VideoNFT, name, symbol, trustedOperator);
  const videoNFT = await VideoNFT.deployed();

  await deployer.deploy(VideoNFTMarketplace, videoNFT.address);
};
