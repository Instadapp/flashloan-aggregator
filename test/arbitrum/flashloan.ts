const hre = require("hardhat");
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
const { ethers } = hre;

import {
  InstaFlashAggregatorArbitrum__factory,
  IERC20__factory,
  IERC20,
  InstaFlashReceiver__factory,
  InstaFlashReceiver,
  InstaFlashAggregatorProxy,
  InstaFlashAggregatorProxy__factory,
} from "../../typechain";

describe("FlashLoan", function () {
  let Aggregator,
    aggregator,
    Receiver,
    receiver: InstaFlashReceiver,
    Proxy,
    proxy;

  let signer: SignerWithAddress;
  let proxyAddr = '0x1f882522DF99820dF8e586b6df8bAae2b91a782d';
  let admin = '0x82D57efa1cE59A0cA3492e189c72B360c7a1Dcdd';

  const master = "0xa9061100d29C3C562a2e2421eb035741C1b42137";

  let ABI = ["function initialize()"];
  let iface = new ethers.utils.Interface(ABI);
  const data = iface.encodeFunctionData("initialize");

  const USDC = "0xff970a61a04b1ca14834a43f5de4533ebddb5cc8";
  const USDT = "0xfd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9";
  const ACC_USDC = "0xce2cc46682e9c6d5f174af598fb4931a9c0be68e";
  const ACC_USDT = "0x0db3fe3b770c95a0b99d1ed6f2627933466c0dd8";

  const usdc = ethers.utils.parseUnits("10", 6);
  const usdt = ethers.utils.parseUnits("10", 6);
  const Usdc = ethers.utils.parseUnits("5000", 6);
  const Usdt = ethers.utils.parseUnits("5000", 6);

  const _data = "0x";
  let _instaData = "0x";

  beforeEach("should set up", async function () {
    [signer] = await ethers.getSigners();
    Aggregator = new InstaFlashAggregatorArbitrum__factory(signer);
    aggregator = await Aggregator.deploy();
    await aggregator.deployed();
    console.log("Aggregator deployed at: ", aggregator.address);

    proxy = new hre.ethers.Contract(
      proxyAddr,
      [{"inputs":[{"internalType":"address","name":"_logic","type":"address"},{"internalType":"address","name":"admin_","type":"address"},{"internalType":"bytes","name":"_data","type":"bytes"}],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"previousAdmin","type":"address"},{"indexed":false,"internalType":"address","name":"newAdmin","type":"address"}],"name":"AdminChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"beacon","type":"address"}],"name":"BeaconUpgraded","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"implementation","type":"address"}],"name":"Upgraded","type":"event"},{"stateMutability":"payable","type":"fallback"},{"inputs":[],"name":"admin","outputs":[{"internalType":"address","name":"admin_","type":"address"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"newAdmin","type":"address"}],"name":"changeAdmin","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"implementation","outputs":[{"internalType":"address","name":"implementation_","type":"address"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"newImplementation","type":"address"}],"name":"upgradeTo","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"newImplementation","type":"address"},{"internalType":"bytes","name":"data","type":"bytes"}],"name":"upgradeToAndCall","outputs":[],"stateMutability":"payable","type":"function"},{"stateMutability":"payable","type":"receive"}],
      ethers.provider,
    )

    await hre.network.provider.request({
      method: 'hardhat_impersonateAccount',
      params: [admin],
    })

    await hre.network.provider.send("hardhat_setBalance", [
      admin,
      ethers.utils.parseEther("10.0").toHexString(),
    ]);

    let impersonateAcc = await ethers.getSigner(admin);

    let tx = await proxy.connect(impersonateAcc).upgradeTo(aggregator.address);
    let receipt = tx.wait();
    console.log("Implementation updated!")

    let addr = await proxy.connect(impersonateAcc).callStatic.implementation();

    console.log("Implementation at: ", addr);

    Receiver = new InstaFlashReceiver__factory(signer);
    receiver = await Receiver.deploy(proxyAddr);
    await receiver.deployed();
    console.log("Receiver deployed at: ", receiver.address);

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
    _instaData = "0x";
  });

  describe("Single token", async function () {
    it("Should be able to take flashLoan of a single token from Balancer", async function () {
      await receiver.flashBorrow([USDC], [Usdc], 5, _data, _instaData);
    });
    it("Should be able to take flashLoan of a single token from AAVE V3", async function () {
      await receiver.flashBorrow([USDC], [Usdc], 9, _data, _instaData);
    });
  });

  describe("Uniswap Route", async function () {
    beforeEach(async function () {
      _instaData = await ethers.utils.defaultAbiCoder.encode(
        ["tuple(address, address, uint24)"],
        [[USDT, USDC, "500"]]
      );
    });
    it("Should be able to take flashLoan of a single token from Uniswap", async function () {
      await receiver.flashBorrow([USDC], [Usdc], 8, _data, _instaData);
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
    it("Should be able to take flashLoan of multiple sorted tokens together from Balancer", async function () {
      await receiver.flashBorrow(
        [USDT, USDC],
        [Usdt, Usdc],
        5,
        _data,
        _instaData
      );
    });
    it("Should be able to take flashLoan of multiple unsorted tokens together from Balancer", async function () {
      await receiver.flashBorrow(
        [USDT, USDC],
        [Usdc, Usdt],
        5,
        _data,
        _instaData
      );
    });
    it("Should be able to take flashLoan of multiple unsorted tokens together from AAVE V3", async function () {
      await receiver.flashBorrow(
        [USDT, USDC],
        [Usdc, Usdt],
        9,
        _data,
        _instaData
      );
    });

    describe("Uniswap Route", async function () {
      beforeEach(async function () {
        _instaData = await ethers.utils.defaultAbiCoder.encode(
          ["tuple(address, address, uint24)"],
          [[USDT, USDC, "500"]]
        );
      });
      it("Should be able to take flashLoan of multiple tokens together from Uniswap", async function () {
        await receiver.flashBorrow(
          [USDT, USDC],
          [Usdc, Usdt],
          8,
          _data,
          _instaData
        );
      });
    });
  });
});
