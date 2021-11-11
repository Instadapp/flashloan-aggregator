const hre = require("hardhat");
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
const { ethers } = hre;

import {
  InstaFlashloanAggregator,
  InstaFlashloanAggregator__factory,
  IERC20__factory,
  IERC20,
  InstaFlashReceiver__factory,
  InstaFlashReceiver,
} from "../../typechain";

describe("FlashLoan", function () {
  let Resolver, resolver, Receiver, receiver: InstaFlashReceiver;
  let signer: SignerWithAddress;

  const DAI = "0x6b175474e89094c44da98b954eedeac495271d0f";
  const USDT = "0xdac17f958d2ee523a2206206994597c13d831ec7";
  const ACC_DAI = "0x9a7a9d980ed6239b89232c012e21f4c210f4bef1";
  const ACC_USDT = "0x6D5Be15f9Aa170e207C043CDf8E0BaDbF2A48ed0";

  const dai = ethers.utils.parseUnits("10", 18);
  const usdt = ethers.utils.parseUnits("10", 6);
  const Dai = ethers.utils.parseUnits("5000", 18);
  const Usdt = ethers.utils.parseUnits("5000", 6);
  const zeroAddr =
    "0x0000000000000000000000000000000000000000000000000000000000000000";

  beforeEach(async function () {
    [signer] = await ethers.getSigners();
    Resolver = new InstaFlashloanAggregator__factory(signer);
    resolver = await Resolver.deploy();
    await resolver.deployed();

    await resolver.addTokenToCtoken([
      "0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643",
      "0xf650C3d88D12dB855b8bf7D11Be6C55A4e07dCC9",
      "0x39AA39c021dfbaE8faC545936693aC917d5E7563",
    ]); // DAI, USDT, USDC

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
    it("Should be able to take flashLoan of a single token from MakerDAO", async function () {
      await receiver.flashBorrow([DAI], [Dai], 2, zeroAddr);
    });
    it("Should be able to take flashLoan of a single token from Compound(MakerDAO)", async function () {
      await receiver.flashBorrow([DAI], [Dai], 3, zeroAddr);
    });
    it("Should be able to take flashLoan of a single token from AAVE(MakerDAO)", async function () {
      await receiver.flashBorrow([DAI], [Dai], 4, zeroAddr);
    });
    it("Should be able to take flashLoan of a single token from Balancer", async function () {
      await receiver.flashBorrow([DAI], [Dai], 5, zeroAddr);
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
    it("Should be able to take flashLoan of multiple tokens together from MakerDAO", async function () {
      await receiver.flashBorrow([DAI, USDT], [Dai, Usdt], 2, zeroAddr);
    });
    it("Should be able to take flashLoan of multiple tokens together from Compound(MakerDAO)", async function () {
      await receiver.flashBorrow([DAI, USDT], [Dai, Usdt], 3, zeroAddr);
    });
    it("Should be able to take flashLoan of multiple tokens together from AAVE(MakerDAO)", async function () {
      await receiver.flashBorrow([DAI, USDT], [Dai, Usdt], 4, zeroAddr);
    });
    it("Should be able to take flashLoan of multiple tokens together from Balancer", async function () {
      await receiver.flashBorrow([DAI, USDT], [Dai, Usdt], 5, zeroAddr);
    });
  });
});
