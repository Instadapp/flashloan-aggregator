const hre = require('hardhat')
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
const { ethers } = hre

import {
    BalancerImplementationArbitrum__factory,
    UniswapImplementationArbitrum__factory,
    InstaFlashAggregatorProxy__factory,
    IERC20__factory,
    InstaFlashReceiver__factory,
    InstaFlashReceiver,
    InstaFlashAggregatorArbitrum__factory,
  } from '../../typechain'
  
  describe('FlashLoan', function () {
    let Aggregator,
      aggregator,
      Receiver,
      receiver: InstaFlashReceiver,
      BalancerImp,
      UniswapImp,
      balancerImpl,
      uniswapImpl,
      proxyAddr = "0x1f882522DF99820dF8e586b6df8bAae2b91a782d",
      admin = "0x82D57efa1cE59A0cA3492e189c72B360c7a1Dcdd",
      adminSigner;
  
    let signer: SignerWithAddress
  
    const master = '0xa8c31E39e40E6765BEdBd83D92D6AA0B33f1CCC5'
    const aaveLendingAddr = '0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9'

    let iface = new ethers.utils.Interface(["function initialize(address bImp,address uImp)"]);

    const USDC = "0xff970a61a04b1ca14834a43f5de4533ebddb5cc8";
    const USDT = "0xfd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9";
    const ACC_USDC = "0xce2cc46682e9c6d5f174af598fb4931a9c0be68e";
    const ACC_USDT = "0x0db3fe3b770c95a0b99d1ed6f2627933466c0dd8";
    //usdt < usdc

    const usdc = ethers.utils.parseUnits("10", 6);
    const usdt = ethers.utils.parseUnits("10", 6);
    const Usdc = ethers.utils.parseUnits("5000", 6);
    const Usdt = ethers.utils.parseUnits("5000", 6);
  
    const _data = '0x'
  
    let _instaData = '0x'
  
    beforeEach('Should set up', async function () {
      ;[signer] = await ethers.getSigners()
  
      Aggregator = new InstaFlashAggregatorArbitrum__factory(signer)
      aggregator = await Aggregator.deploy()
      await aggregator.deployed()
      console.log("aggregator: ", aggregator.address)

      BalancerImp = new BalancerImplementationArbitrum__factory(signer)
      balancerImpl = await BalancerImp.deploy()
      await balancerImpl.deployed()
      console.log("balancerImpl: ", balancerImpl.address)

      UniswapImp = new UniswapImplementationArbitrum__factory(signer)
      uniswapImpl = await UniswapImp.deploy()
      await uniswapImpl.deployed()
      console.log("uniswapImpl: ", uniswapImpl.address)

      const proxy = new ethers.Contract(
        proxyAddr,
        InstaFlashAggregatorProxy__factory.abi,
        ethers.provider,
      )

      await hre.network.provider.request({
          method: 'hardhat_impersonateAccount',
          params: [admin],
      })

      adminSigner = await ethers.getSigner(admin);

      await hre.network.provider.send('hardhat_setBalance', [
        admin,
        ethers.utils.parseEther('10.0').toHexString(),
      ])

      const dataNew = await iface.encodeFunctionData('initialize', [balancerImpl.address,uniswapImpl.address])
      console.log("dataNew: ", dataNew)
      await proxy.connect(adminSigner).upgradeToAndCall(aggregator.address, dataNew);

      Receiver = new InstaFlashReceiver__factory(signer);
      receiver = await Receiver.deploy(proxyAddr);
      await receiver.deployed();
      console.log("receiver: ", receiver.address)
  
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
      await token_usdc.connect(signer_usdc).transfer(proxyAddr, Usdc);
  
      await hre.network.provider.request({
        method: "hardhat_stopImpersonatingAccount",
        params: [ACC_USDC],
      });
      _instaData = "0x";
    })
  
    describe("Single token", async function () {
      it("Should be able to take flashLoan of a single token from Balancer", async function () {
        await receiver.flashBorrow([USDC], [Usdc], 5, _data, _instaData);
      });
      it("Should be able to take flashLoan of a single token from FLA", async function () {
        await receiver.flashBorrow([USDC], [Usdc], 9, _data, _instaData)
      })
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
        await token.connect(signer_usdt).transfer(proxyAddr, Usdt);
  
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
          [USDC, USDT],
          [Usdc, Usdt],
          5,
          _data,
          _instaData
        );
      });
      it("Should be able to take flashLoan of multiple tokens together from FLA", async function () {
        await receiver.flashBorrow(
          [USDT, USDC],
          [Usdt, Usdc],
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
            [Usdt, Usdc],
            8,
            _data,
            _instaData
          );
        });
      });
    });
  })
