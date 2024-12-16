const Tokenus = artifacts.require("Tokenus");
const Channel = artifacts.require("Channel");
const Swap = artifacts.require("Swap");
const VideoNFT = artifacts.require("VideoNFT");

module.exports = async function (deployer) {

  await deployer.deploy(Tokenus);
  const tokenus = await Tokenus.deployed();

  await deployer.deploy(Channel);
  const channel = await Channel.deployed(); 

  await deployer.deploy(Swap, tokenus.address, channel.address);
  const swap = await Swap.deployed(); 

  deployer.deploy(VideoNFT);
};