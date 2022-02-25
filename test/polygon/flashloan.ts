const hre = require("hardhat");
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
const { ethers } = hre;

import {
  InstaFlashAggregatorPolygon,
  InstaFlashAggregatorPolygon__factory,
  IERC20__factory,
  IERC20,
  InstaFlashReceiver__factory,
  InstaFlashReceiver,
  InstaFlashAggregatorProxy,
  InstaFlashAggregatorProxy__factory,
  InstaFlashAggregatorAdmin,
  InstaFlashAggregatorAdmin__factory,
} from "../../typechain";

describe("FlashLoan", function () {
  let Aggregator,
    aggregator,
    Receiver,
    receiver: InstaFlashReceiver,
    Proxy,
    proxy,
    Admin,
    admin;
  let signer: SignerWithAddress;

  const master = "0xa9061100d29C3C562a2e2421eb035741C1b42137";

  let ABI = ["function initialize()"];
  let iface = new ethers.utils.Interface(ABI);
  const data = iface.encodeFunctionData("initialize");

  const DAI = "0x8f3cf7ad23cd3cadbd9735aff958023239c6a063";
  const USDT = "0xc2132d05d31c914a87c6611c10748aeb04b58e8f";
  const ACC_DAI = "0x4a35582a710e1f4b2030a3f826da20bfb6703c09";
  const ACC_USDT = "0x0d0707963952f2fba59dd06f2b425ace40b492fe";

  const dai = ethers.utils.parseUnits("1000", 18);
  const usdt = ethers.utils.parseUnits("1000", 6);
  const Dai = ethers.utils.parseUnits("5000", 18);
  const Usdt = ethers.utils.parseUnits("5000", 6);

  const _data = "0x";

  let _instaData = "0x";

  beforeEach(async function () {
    [signer] = await ethers.getSigners();
    Aggregator = new InstaFlashAggregatorPolygon__factory(signer);
    aggregator = await Aggregator.deploy();
    await aggregator.deployed();

    Admin = new InstaFlashAggregatorAdmin__factory(signer);
    admin = await Admin.deploy(master);
    await admin.deployed();

    Proxy = new InstaFlashAggregatorProxy__factory(signer);
    proxy = await Proxy.deploy(aggregator.address, admin.address, data);
    await proxy.deployed();

    Receiver = new InstaFlashReceiver__factory(signer);
    receiver = await Receiver.deploy(proxy.address);
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
    _instaData = "0x";
  });

  describe("Single token", async function () {
    it("Should be able to take flashLoan of a single token from AAVE", async function () {
      await receiver.flashBorrow([DAI], [Dai], 1, _data, _instaData);
    });
    it("Should be able to take flashLoan of a single token from Balancer", async function () {
      await receiver.flashBorrow([DAI], [Dai], 5, _data, _instaData);
    });
    it("Should be able to take flashLoan of a single token from AAVE(Balancer)", async function () {
      await receiver.flashBorrow([DAI], [Dai], 7, _data, _instaData);
    });

    describe("Uniswap Route", async function () {
      beforeEach(async function () {
        _instaData = await ethers.utils.defaultAbiCoder.encode(
          ["tuple(address, address, uint24)"],
          [[USDT, DAI, "500"]]
        );
      });
      it("Should be able to take flashLoan of a single token from Uniswap", async function () {
        await receiver.flashBorrow([DAI], [Dai], 8, _data, _instaData);
      });
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
      _instaData = "0x";
    });
    it("Should be able to take flashLoan of multiple tokens together from AAVE", async function () {
      await receiver.flashBorrow(
        [DAI, USDT],
        [Dai, Usdt],
        1,
        _data,
        _instaData
      );
    });
    it("Should be able to take flashLoan of multiple sorted tokens together from Balancer", async function () {
      await receiver.flashBorrow(
        [DAI, USDT],
        [Dai, Usdt],
        5,
        _data,
        _instaData
      );
    });
    it("Should be able to take flashLoan of multiple unsorted tokens together from Balancer", async function () {
      await receiver.flashBorrow(
        [USDT, DAI],
        [Usdt, Dai],
        5,
        _data,
        _instaData
      );
    });
    it("Should be able to take flashLoan of multiple tokens together from AAVE(Balancer)", async function () {
      await receiver.flashBorrow(
        [DAI, USDT],
        [Dai, Usdt],
        7,
        _data,
        _instaData
      );
    });

    describe("Uniswap Route", async function () {
      beforeEach(async function () {
        _instaData = await ethers.utils.defaultAbiCoder.encode(
          ["tuple(address, address, uint24)"],
          [[USDT, DAI, "500"]]
        );
      });
      it("Should be able to take flashLoan of multiple tokens together from Uniswap", async function () {
        await receiver.flashBorrow(
          [DAI, USDT],
          [Dai, Usdt],
          8,
          _data,
          _instaData
        );
      });
    });
  });
});
