const hre = require('hardhat')
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
const { ethers } = hre

import {
  InstaFlashAggregatorPolygon__factory,
  IERC20__factory,
  InstaFlashReceiver__factory,
  InstaFlashReceiver,
  InstaFlashAggregatorProxy__factory,
  UniswapImplementationPolygon__factory,
  BalancerImplementationPolygon__factory,
  AaveImplementationPolygon__factory
} from '../../typechain'

describe('FlashLoan', function () {
  let Aggregator,
    aggregator,
    Receiver,
    receiver: InstaFlashReceiver,
    implUniswap,
    ImplUniswap,
    implBalancer,
    ImplBalancer,
    implAave,
    ImplAave,
    proxyAddr = "0xB2A7F20D10A006B0bEA86Ce42F2524Fde5D6a0F4",
    admin = "0x90cf378a297c7ef6dabed36ea5e112c6646bb3a4",
    adminSigner

  let signer: SignerWithAddress

  const master = '0xa9061100d29C3C562a2e2421eb035741C1b42137'

  let ABI = ['function initialize(address aave, address balancer, address uniswap)']
  let iface = new ethers.utils.Interface(ABI)

  const DAI = '0x8f3cf7ad23cd3cadbd9735aff958023239c6a063'
  const USDT = '0xc2132d05d31c914a87c6611c10748aeb04b58e8f'
  const ACC_DAI = '0x4a35582a710e1f4b2030a3f826da20bfb6703c09'
  const ACC_USDT = '0x0d0707963952f2fba59dd06f2b425ace40b492fe'
  //dai < usdt

  const dai = ethers.utils.parseUnits('1000', 18)
  const usdt = ethers.utils.parseUnits('1000', 6)
  const Dai = ethers.utils.parseUnits('10', 18)
  const Usdt = ethers.utils.parseUnits('100', 6)

  const _data = '0x'

  let _instaData = '0x'

  beforeEach(async function () {
    ;[signer] = await ethers.getSigners()
    Aggregator = new InstaFlashAggregatorPolygon__factory(signer)
    aggregator = await Aggregator.deploy()
    await aggregator.deployed()
    console.log("aggregator deployed at: ", aggregator.address);

    ImplAave = new AaveImplementationPolygon__factory(signer)
    implAave = await ImplAave.deploy()
    await implAave.deployed()
    console.log("implAave deployed at: ", implAave.address);

    ImplBalancer = new BalancerImplementationPolygon__factory(signer)
    implBalancer = await ImplBalancer.deploy()
    await implBalancer.deployed()
    console.log("implBalancer deployed at: ", implBalancer.address);

    ImplUniswap = new UniswapImplementationPolygon__factory(signer)
    implUniswap = await ImplUniswap.deploy()
    await implUniswap.deployed()
    console.log("implUniswap deployed at: ", implUniswap.address);

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

    const data = iface.encodeFunctionData('initialize', [implAave.address, implBalancer.address,implUniswap.address])
    await proxy.connect(adminSigner).upgradeToAndCall(aggregator.address, data);

    Receiver = new InstaFlashReceiver__factory(signer)
    receiver = await Receiver.deploy(proxy.address)
    await receiver.deployed()
    console.log("receiver deployed at: ", receiver.address);

    const token_dai = new ethers.Contract(
      DAI,
      IERC20__factory.abi,
      ethers.provider,
    )

    await hre.network.provider.send('hardhat_setBalance', [
      ACC_DAI,
      ethers.utils.parseEther('10.0').toHexString(),
    ])

    await hre.network.provider.request({
      method: 'hardhat_impersonateAccount',
      params: [ACC_DAI],
    })

    const signer_dai = await ethers.getSigner(ACC_DAI)
    await token_dai.connect(signer_dai).transfer(receiver.address, dai)

    await hre.network.provider.request({
      method: 'hardhat_stopImpersonatingAccount',
      params: [ACC_DAI],
    })
    _instaData = '0x'
  })

  describe('Single token', async function () {
    it('Should be able to take flashLoan of a single token from AAVE', async function () {
      await receiver.flashBorrow([DAI], [Dai], 1, _data, _instaData)
    })
    it('Should be able to take flashLoan of a single token from Balancer', async function () {
      await receiver.flashBorrow([DAI], [Dai], 5, _data, _instaData)
    })
    it('Should be able to take flashLoan of a single token from AAVE(Balancer)', async function () {
      await receiver.flashBorrow([DAI], [Dai], 7, _data, _instaData)
    })
    it("Should be able to take flashLoan of a single token from FLA", async function () {
      await receiver.flashBorrow([DAI], [Dai], 9, _data, _instaData)
    })

    describe('Uniswap Route', async function () {
      beforeEach(async function () {
        _instaData = await ethers.utils.defaultAbiCoder.encode(
          ['tuple(address, address, uint24)'],
          [[DAI, USDT, '500']],
        )
      })
      it('Should be able to take flashLoan of a single token from Uniswap', async function () {
        await receiver.flashBorrow([DAI], [Dai], 8, _data, _instaData)
      })
    })
  })

  describe('Multi token', async function () {
    beforeEach(async function () {
      const token = new ethers.Contract(
        USDT,
        IERC20__factory.abi,
        ethers.provider,
      )

      await hre.network.provider.send('hardhat_setBalance', [
        ACC_USDT,
        ethers.utils.parseEther('10.0').toHexString(),
      ])

      await hre.network.provider.request({
        method: 'hardhat_impersonateAccount',
        params: [ACC_USDT],
      })

      const signer_usdt = await ethers.getSigner(ACC_USDT)
      await token.connect(signer_usdt).transfer(receiver.address, usdt)
      await token.connect(signer_usdt).transfer(proxyAddr, usdt)

      await hre.network.provider.request({
        method: 'hardhat_stopImpersonatingAccount',
        params: [ACC_USDT],
      })
      _instaData = '0x'
    })
    it('Should be able to take flashLoan of multiple tokens together from AAVE', async function () {
      await receiver.flashBorrow([DAI, USDT], [Dai, Usdt], 1, _data, _instaData)
    })
    it('Should be able to take flashLoan of multiple sorted tokens together from Balancer', async function () {
      await receiver.flashBorrow([DAI, USDT], [Dai, Usdt], 5, _data, _instaData)
    })
    it('Should be able to take flashLoan of multiple unsorted tokens together from Balancer', async function () {
      await receiver.flashBorrow([USDT, DAI], [Usdt, Dai], 5, _data, _instaData)
    })
    it('Should be able to take flashLoan of multiple tokens together from AAVE(Balancer)', async function () {
      await receiver.flashBorrow([DAI, USDT], [Dai, Usdt], 7, _data, _instaData)
    })
    it("Should be able to take flashLoan of multiple tokens together from FLA", async function () {
      await receiver.flashBorrow([USDT, DAI], [Usdt, Dai], 9, _data, _instaData);
    })

    describe('Uniswap Route', async function () {
      beforeEach(async function () {
        _instaData = await ethers.utils.defaultAbiCoder.encode(
          ['tuple(address, address, uint24)'],
          [[USDT, DAI, '500']],
        )
      })
      it('Should be able to take flashLoan of multiple unsorted tokens together from Uniswap', async function () {
        await receiver.flashBorrow(
          [USDT, DAI],
          [Usdt, Dai],
          8,
          _data,
          _instaData,
        )
      })
      it('Should be able to take flashLoan of multiple tokens sorted together from Uniswap', async function () {
        await receiver.flashBorrow(
          [DAI, USDT],
          [Dai, Usdt],
          8,
          _data,
          _instaData,
        )
      })
    })
  })
})
