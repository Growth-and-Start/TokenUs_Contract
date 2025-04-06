const VideoNFT = artifacts.require("VideoNFT");
const VideoNFTMarketplace = artifacts.require("VideoNFTMarketplace");

module.exports = async function (deployer) {
  await deployer.deploy(VideoNFT, "VideoNFT", "VNFT");
  const videoNFT = await VideoNFT.deployed();

  await deployer.deploy(VideoNFTMarketplace, videoNFT.address);
};
