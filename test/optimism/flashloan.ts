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

  const DAI = "0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1";
  const USDT = "0x94b008aA00579c1307B0EF2c499aD98a8ce58e58";
  const ACC_DAI = "0xadb35413ec50e0afe41039eac8b930d313e94fa4";
  const ACC_USDT = "0x9d39fc627a6d9d9f8c831c16995b209548cc3401";

  const dai = ethers.utils.parseUnits("1000", 18);
  const usdt = ethers.utils.parseUnits("1000", 6);
  const Dai = ethers.utils.parseUnits("5000", 18);
  const Usdt = ethers.utils.parseUnits("5000", 6);

  const _data = "0x";

  let _instaData = "";

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

    _instaData = await ethers.utils.defaultAbiCoder.encode(
      ["tuple(address, address, uint24)"],
      [[USDT, DAI, "500"]]
    );
  });

  describe("Single token", async function () {
    it("Should be able to take flashLoan of a single token from Uniswap", async function () {
      await receiver.flashBorrow([DAI, USDT], [Dai, 0], 8, _data, _instaData);
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
