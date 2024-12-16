const Tokenus = artifacts.require("Tokenus");
const Channel = artifacts.require("Channel");
const Swap = artifacts.require("Swap");

contract("Swap Contract", (accounts) => {
    let tokenus, channel, swap;

    // 초기 상태 설정
    beforeEach(async () => {
        // 1. Tokenus 배포
        tokenus = await Tokenus.new();
        // 2. Channel 배포
        channel = await Channel.new();
        // 3. Swap 배포 (Tokenus와 Channel 주소 전달)
        swap = await Swap.new(tokenus.address, channel.address);

        // 4. 초기 토큰 분배
        // accounts[1]에게 10 TUS 전송
        await tokenus.transfer(accounts[1], web3.utils.toWei("10", "ether"));
        // Swap 컨트랙트에 1000 CNL 예치
        await channel.transfer(swap.address, web3.utils.toWei("1000", "ether"));
    });

    // 테스트: 사용자가 1 TUS로 100 CNL을 교환
    it("should allow user to swap 1 TUS for 100 CNL", async () => {
        // accounts[1]에서 Swap 컨트랙트에 TUS 사용 승인
        await tokenus.approve(swap.address, web3.utils.toWei("1", "ether"), { from: accounts[1] });

        // accounts[1]이 1 TUS로 스왑 실행
        await swap.buyToken(web3.utils.toWei("1", "ether"), { from: accounts[1] });

        // 잔액 확인
        const tusBalance = await tokenus.balanceOf(accounts[1]);
        const cnlBalance = await channel.balanceOf(accounts[1]);
        const swapCnlBalance = await channel.balanceOf(swap.address);

        // 사용자의 TUS는 1 감소
        assert.equal(tusBalance.toString(), web3.utils.toWei("9", "ether"), "TUS balance should be 9");
        // 사용자의 CNL은 100 증가
        assert.equal(cnlBalance.toString(), web3.utils.toWei("100", "ether"), "CNL balance should be 100");
        // Swap 컨트랙트의 CNL 유동성은 100 감소
        assert.equal(swapCnlBalance.toString(), web3.utils.toWei("900", "ether"), "Swap contract CNL balance should be 900");
    });
});
