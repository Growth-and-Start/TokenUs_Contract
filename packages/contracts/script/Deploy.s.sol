// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/NFT.sol";
import "../src/SplitFactory.sol";
import "../src/Market.sol";

contract Deploy is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address feeVault = vm.envAddress("FEE_VAULT");
        vm.startBroadcast(pk);
        NFT nft = new NFT();
        SplitFactory factory = new SplitFactory();
        Market market = new Market(feeVault);
        vm.stopBroadcast();

        console2.log("NFT", address(nft));
        console2.log("SplitFactory", address(factory));
        console2.log("Market", address(market));
    }
}
