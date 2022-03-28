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
  const USDT = '0xc7198437980c041c805a1edcba50c1ce5db95118'
  const ACC_DAI = '0xed2a7edd7413021d440b09d654f3b87712abab66'
  const ACC_USDT = '0xed2a7edd7413021d440b09d654f3b87712abab66'

  const dai = ethers.utils.parseUnits('10', 18)
  const usdt = ethers.utils.parseUnits('10', 6)
  const Dai = ethers.utils.parseUnits('5000', 18)
  const Usdt = ethers.utils.parseUnits('5000', 6)

  const zeroAddr =
    '0x0000000000000000000000000000000000000000000000000000000000000000'

    let _instaData = ''


  beforeEach(async function () {
    ;[signer] = await ethers.getSigners()
    Aggregator = new InstaFlashAggregatorAvalanche__factory(signer)
    aggregator = await Aggregator.deploy()
    await aggregator.deployed()


    Proxy = new InstaFlashAggregatorProxy__factory(signer)
    proxy = await Proxy.deploy(aggregator.address, master, data)
    await proxy.deployed()

    Receiver = new InstaFlashReceiver__factory(signer)
    receiver = await Receiver.deploy(proxy.address)
    await receiver.deployed()

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

      await hre.network.provider.request({
        method: 'hardhat_stopImpersonatingAccount',
        params: [ACC_USDT],
      })
      _instaData = '0x'
    })
    it('Should be able to take flashLoan of multiple tokens together from AAVE V2', async function () {
      await receiver.flashBorrow([DAI, USDT], [Dai, Usdt], 1, zeroAddr,_instaData )
    })
    it('Should be able to take flashLoan of multiple tokens together from AAVE V3', async function () {
      await receiver.flashBorrow([DAI, USDT], [Dai, Usdt], 9, zeroAddr,_instaData )
    })
  })
})
