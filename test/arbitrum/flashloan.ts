const hre = require("hardhat");
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
const { ethers } = hre;

import {
  InstaFlashloanAggregatorArbitrum,
  InstaFlashloanAggregatorArbitrum__factory,
  IERC20__factory,
  IERC20,
  InstaFlashReceiver__factory,
  InstaFlashReceiver,
} from "../../typechain";

describe("FlashLoan", function () {
  let Resolver, resolver, Receiver, receiver: InstaFlashReceiver;
  let signer: SignerWithAddress;

  const USDC = "0xff970a61a04b1ca14834a43f5de4533ebddb5cc8";
  const USDT = "0xfd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9";
  const ACC_USDC = "0xce2cc46682e9c6d5f174af598fb4931a9c0be68e";
  const ACC_USDT = "0x0db3fe3b770c95a0b99d1ed6f2627933466c0dd8";

  const usdc = ethers.utils.parseUnits("10", 6);
  const usdt = ethers.utils.parseUnits("10", 6);
  const Usdc = ethers.utils.parseUnits("5000", 6);
  const Usdt = ethers.utils.parseUnits("5000", 6);
  
  const zeroAddr =
    "0x0000000000000000000000000000000000000000000000000000000000000000";

  beforeEach(async function () {
    [signer] = await ethers.getSigners();
    Resolver = new InstaFlashloanAggregatorArbitrum__factory(signer);
    resolver = await Resolver.deploy();
    await resolver.deployed();

    Receiver = new InstaFlashReceiver__factory(signer);
    receiver = await Receiver.deploy(resolver.address);
    await receiver.deployed();

    const token_usdc = new ethers.Contract(
      USDC,
      IERC20__factory.abi,
      ethers.provider
    );

    await hre.network.provider.send("hardhat_setBalance", [
      ACC_USDC,
      ethers.utils.parseEther("10.0").toHexString(),
    ]);

    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [ACC_USDC],
    });

    const signer_usdc = await ethers.getSigner(ACC_USDC);
    await token_usdc.connect(signer_usdc).transfer(receiver.address, usdc);

    await hre.network.provider.request({
      method: "hardhat_stopImpersonatingAccount",
      params: [ACC_USDC],
    });
  });

  describe("Single token", async function () {
    it("Should be able to take flashLoan of a single token from Balancer", async function () {
      await receiver.flashBorrow([USDC], [Usdc], 1, zeroAddr);
    });
  });

  describe("Multi token", async function () {
    beforeEach(async function () {
      const token = new ethers.Contract(
        USDT,
        IERC20__factory.abi,
        ethers.provider
      );

      await hre.network.provider.send("hardhat_setBalance", [
        ACC_USDT,
        ethers.utils.parseEther("10.0").toHexString(),
      ]);

      await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [ACC_USDT],
      });

      const signer_usdt = await ethers.getSigner(ACC_USDT);
      await token.connect(signer_usdt).transfer(receiver.address, usdt);

      await hre.network.provider.request({
        method: "hardhat_stopImpersonatingAccount",
        params: [ACC_USDT],
      });
    });
    it("Should be able to take flashLoan of multiple tokens together from Balancer", async function () {
      await receiver.flashBorrow([USDT, USDC], [Usdt, Usdc], 1, zeroAddr);
    });
  });
});
