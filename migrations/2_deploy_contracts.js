const Tokenus = artifacts.require("Tokenus");
const Channel = artifacts.require("Channel");
const Swap = artifacts.require("Swap");
const VideoNFT = artifacts.require("VideoNFT");
const VideoNFTMarketplace = artifacts.require("VideoNFTMarketplace");

module.exports = async function (deployer) {
  // (1) 필수 컨트랙트 생략
  // await deployer.deploy(Tokenus);
  // const tokenus = await Tokenus.deployed();

  // await deployer.deploy(Channel);
  // const channel = await Channel.deployed(); 

  // await deployer.deploy(Swap, tokenus.address, channel.address);
  // const swap = await Swap.deployed(); 

  // (2) VideoNFT 배포 (name/symbol은 임시로 넣어도 됨 — 사용 안 함)
  await deployer.deploy(VideoNFT, "VideoNFT", "VNFT");
  const videoNFT = await VideoNFT.deployed();

  // (3) VideoNFTMarketplace 배포
  // await deployer.deploy(VideoNFTMarketplace, videoNFT.address);
};
