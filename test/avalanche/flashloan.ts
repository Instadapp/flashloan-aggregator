const hre = require("hardhat");
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
const { ethers } = hre;

import {
  InstaFlashloanAggregatorAvalanche,
  InstaFlashloanAggregatorAvalanche__factory,
  IERC20__factory,
  IERC20,
  InstaFlashReceiver__factory,
  InstaFlashReceiver,
} from "../../typechain";

describe("FlashLoan", function () {
  let Resolver, resolver, Receiver, receiver: InstaFlashReceiver;
  let signer: SignerWithAddress;

  const DAI = "0xbA7dEebBFC5fA1100Fb055a87773e1E99Cd3507a";
  const USDT = "0xde3A24028580884448a5397872046a019649b084";
  const ACC_DAI = "0x82269802d729a1f6b7b4523c5d3f80881e807904";
  const ACC_USDT = "0xde3a24028580884448a5397872046a019649b084";

  const dai = ethers.utils.parseUnits("10", 18);
  const usdt = ethers.utils.parseUnits("10", 6);
  const Dai = ethers.utils.parseUnits("5000", 18);
  const Usdt = ethers.utils.parseUnits("5000", 6);
  
  const zeroAddr =
    "0x0000000000000000000000000000000000000000000000000000000000000000";

  beforeEach(async function () {
    [signer] = await ethers.getSigners();
    Resolver = new InstaFlashloanAggregatorAvalanche__factory(signer);
    resolver = await Resolver.deploy();
    await resolver.deployed();

    Receiver = new InstaFlashReceiver__factory(signer);
    receiver = await Receiver.deploy(resolver.address);
    await receiver.deployed();

    const token_dai = new ethers.Contract(
      DAI,
      IERC20__factory.abi,
      ethers.provider
    );

    await hre.network.provider.send("hardhat_setBalance", [
      ACC_DAI,
      ethers.utils.parseEther("10.0").toHexString(),
    ]);

    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [ACC_DAI],
    });

    const signer_dai = await ethers.getSigner(ACC_DAI);
    await token_dai.connect(signer_dai).transfer(receiver.address, dai);

    await hre.network.provider.request({
      method: "hardhat_stopImpersonatingAccount",
      params: [ACC_DAI],
    });
  });

  describe("Single token", async function () {
    it("Should be able to take flashLoan of a single token from AAVE", async function () {
      await receiver.flashBorrow([DAI], [Dai], 1, zeroAddr);
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
    it("Should be able to take flashLoan of multiple tokens together from AAVE", async function () {
      await receiver.flashBorrow([DAI, USDT], [Dai, Usdt], 1, zeroAddr);
    });
  });
});
