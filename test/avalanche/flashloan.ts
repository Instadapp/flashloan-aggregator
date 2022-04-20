const hre = require('hardhat')
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
const { ethers } = hre

import {
  InstaFlashAggregatorAvalanche,
  InstaFlashAggregatorAvalanche__factory,
  IERC20__factory,
  IERC20,
  InstaFlashReceiver__factory,
  InstaFlashReceiver,
  InstaFlashAggregatorProxy,
  InstaFlashAggregatorProxy__factory,
} from '../../typechain'

describe('FlashLoan', function () {
  let Aggregator,
    aggregator,
    Receiver,
    receiver: InstaFlashReceiver,
    Proxy,
    proxy;

  let signer: SignerWithAddress

  const master = '0xa9061100d29C3C562a2e2421eb035741C1b42137'

  let ABI = ['function initialize()']
  let iface = new ethers.utils.Interface(ABI)
  const data = iface.encodeFunctionData('initialize')

  const DAI = '0xd586e7f844cea2f87f50152665bcbc2c279d8d70'
  const USDT = '0xc7198437980c041c805a1edcba50c1ce5db95118'//USDT.e on Aave V2
  const USDt = '0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7'//USDT on Aave V3
  const ACC_DAI = '0xed2a7edd7413021d440b09d654f3b87712abab66'
  const ACC_USDT = '0xed2a7edd7413021d440b09d654f3b87712abab66'
  const ACC_USDt = '0x876EabF441B2EE5B5b0554Fd502a8E0600950cFa'

  const dai = ethers.utils.parseUnits('10', 18)
  const usdte = ethers.utils.parseUnits('10', 6)
  const usdt = ethers.utils.parseUnits('10', 6)
  const Dai = ethers.utils.parseUnits('5000', 18)
  const Usdte = ethers.utils.parseUnits('5000', 6)
  const Usdt = ethers.utils.parseUnits('5000', 6) 

  const zeroAddr =
    '0x0000000000000000000000000000000000000000000000000000000000000000'

    let _instaData = ''


  beforeEach(async function () {
    ;[signer] = await ethers.getSigners()
    Aggregator = new InstaFlashAggregatorAvalanche__factory(signer)
    aggregator = await Aggregator.deploy()
    await aggregator.deployed()
    console.log("aggregator at: ", aggregator.address);


    Proxy = new InstaFlashAggregatorProxy__factory(signer)
    proxy = await Proxy.deploy(aggregator.address, master, data)
    await proxy.deployed()
    console.log("proxy at: ", proxy.address);

    Receiver = new InstaFlashReceiver__factory(signer)
    receiver = await Receiver.deploy(proxy.address)
    await receiver.deployed()
    console.log("receiver at: ", receiver.address);

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
    it('Should be able to take flashLoan of a single token from AAVE V2', async function () {
      await receiver.flashBorrow([DAI], [Dai], 1, zeroAddr,_instaData)
    })
    it('Should be able to take flashLoan of a single token from AAVE V3', async function () {
      await receiver.flashBorrow([DAI], [Dai], 9, zeroAddr,_instaData)
    })
  })

  describe('Multi token - V2', async function () {
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

      const signer_usdte = await ethers.getSigner(ACC_USDT)
      await token.connect(signer_usdte).transfer(receiver.address, usdte)

      await hre.network.provider.request({
        method: 'hardhat_stopImpersonatingAccount',
        params: [ACC_USDT],
      })
      _instaData = '0x'
    })
    it('Should be able to take flashLoan of multiple tokens together from AAVE V2', async function () {
      await receiver.flashBorrow([DAI, USDT], [Dai, Usdte], 1, zeroAddr,_instaData )
    })
  })

  describe('Multi token - V3', async function () {
    beforeEach(async function () {
      const token = new ethers.Contract(
        USDt,
        IERC20__factory.abi,
        ethers.provider,
      )

      await hre.network.provider.send('hardhat_setBalance', [
        ACC_USDt,
        ethers.utils.parseEther('10.0').toHexString(),
      ])

      await hre.network.provider.request({
        method: 'hardhat_impersonateAccount',
        params: [ACC_USDt],
      })

      const signer_usdt = await ethers.getSigner(ACC_USDt)
      await token.connect(signer_usdt).transfer(receiver.address, usdt)
      console.log("user transferred");

      await hre.network.provider.request({
        method: 'hardhat_stopImpersonatingAccount',
        params: [ACC_USDt],
      })
      _instaData = '0x'
    })
    it('Should be able to take flashLoan of multiple tokens together from AAVE V3', async function () {
      await receiver.flashBorrow([DAI, USDt], [Dai, Usdt], 9, zeroAddr,_instaData )
    })
  })
})
