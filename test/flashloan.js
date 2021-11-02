const hre = require("hardhat");
const { ethers } = hre;

describe("FlashLoan", function () {
    const DAI = "0x6b175474e89094c44da98b954eedeac495271d0f";
    const ACC = "0x9a7a9d980ed6239b89232c012e21f4c210f4bef1";
    const dai = ethers.utils.parseUnits("10", 18);
    const Dai = ethers.utils.parseUnits("10000", 18);
    it("Should be able to take flashLoan", async function () {
        const Resolver = await ethers.getContractFactory("InstaFlashloanAggregator");
        const resolver = await Resolver.deploy();
        await resolver.deployed();

        const Receiver = await ethers.getContractFactory("FlashReceiver");
        const receiver = await Receiver.deploy(resolver.address);
        await receiver.deployed();

        const tokenArtifact = await artifacts.readArtifact("IERC20");
        const token = new ethers.Contract(DAI, tokenArtifact.abi, ethers.provider);


        await network.provider.send("hardhat_setBalance", [
            ACC,
            ethers.utils.parseEther('10.0').toHexString(),
        ]);

        await hre.network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [ACC],
        });

        const signer = await ethers.getSigner(ACC);
        await token.connect(signer).transfer(receiver.address, dai);

        await hre.network.provider.request({
            method: "hardhat_stopImpersonatingAccount",
            params: [ACC],
        });

        await receiver.flashBorrow([DAI], [Dai], 1, 0);
    });
});
