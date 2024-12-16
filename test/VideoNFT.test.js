const VideoNFT = artifacts.require("VideoNFT");

contract("VideoNFT", (accounts) => {
    const [creator, buyer] = accounts;

    it("should mint a new Video NFT", async () => {
        const contract = await VideoNFT.deployed();

        await contract.mintVideoNFT(
            "https://example.com/metadata/1",
            5,
            "MyVideoNFT",
            "MVNFT",
            { from: creator }
        );

        const video = await contract.videos(1);
        assert.equal(video.name, "MyVideoNFT", "The name should match");
        assert.equal(video.symbol, "MVNFT", "The symbol should match");
    });

    // it("should allow a user to purchase a token", async () => {
    //     const contract = await VideoNFT.deployed();

    //     await contract.purchaseToken(1, {
    //         from: buyer,
    //         value: web3.utils.toWei("1", "ether"),
    //     });

    //     const owner = await contract.ownerOf(1);
    //     assert.equal(owner, buyer, "The buyer should own the token");
    // });
});
