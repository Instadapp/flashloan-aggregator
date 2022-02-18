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
  InstaFlashAggregatorAdmin,
  InstaFlashAggregatorAdmin__factory,
} from '../../typechain'

describe('FlashLoan', function () {
  let Aggregator,
    aggregator,
    Receiver,
    receiver: InstaFlashReceiver,
    Proxy,
    proxy,
    Admin,
    admin
  let signer: SignerWithAddress

  const master = '0xa9061100d29C3C562a2e2421eb035741C1b42137'

  let ABI = ['function initialize(address[])']
  let iface = new ethers.utils.Interface(ABI)
  const data = iface.encodeFunctionData('initialize' , [ 
    [
      '0xb3c68d69E95B095ab4b33B4cB67dBc0fbF3Edf56', //WAVAX
      '0x338EEE1F7B89CE6272f302bDC4b952C13b221f1d', //WETH
      '0xCEb1cE674f38398432d20bc8f90345E91Ef46fd3', //USDT
      '0xe28965073C49a02923882B8329D3E8C1D805E832', //USDC
      '0x085682716f61a72bf8C573FBaF88CCA68c60E99B', //DAI
      '0xB09b75916C5F4097C8b5812E63e216FEF97661Fc', //WBTC
      '0x18931772Adb90e7f214B6CbC78DdD6E0F090D4B1', //LINK
    ],
    ])

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

  beforeEach(async function () {
    ;[signer] = await ethers.getSigners()
    Aggregator = new InstaFlashAggregatorAvalanche__factory(signer)
    aggregator = await Aggregator.deploy()
    await aggregator.deployed()

    Admin = new InstaFlashAggregatorAdmin__factory(signer)
    admin = await Admin.deploy(master)
    await admin.deployed()

    Proxy = new InstaFlashAggregatorProxy__factory(signer)
    proxy = await Proxy.deploy(aggregator.address, admin.address, data)
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
  })

  describe('Single token', async function () {
    it('Should be able to take flashLoan of a single token from AAVE', async function () {
      await receiver.flashBorrow([DAI], [Dai], 1, zeroAddr)
    })
    it('Should be able to take flashLoan of a single token from CREAM', async function () {
      await receiver.flashBorrow([DAI], [Dai], 8, zeroAddr)
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
    })
    it('Should be able to take flashLoan of multiple tokens together from AAVE', async function () {
      await receiver.flashBorrow([DAI, USDT], [Dai, Usdt], 1, zeroAddr)
    })
    it('Should be able to take flashLoan of multiple tokens together from CREAM', async function () {
      await receiver.flashBorrow([DAI, USDT], [Dai, Usdt], 8, zeroAddr)
    })
  })
})
