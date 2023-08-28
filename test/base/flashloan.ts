const hre = require('hardhat')
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
const { ethers } = hre

import {
  InstaFlashAggregatorBase,
  InstaFlashAggregatorBase__factory,
  IERC20__factory,
  IERC20,
  InstaFlashReceiver__factory,
  InstaFlashReceiver,
  InstaFlashAggregatorProxy,
  InstaFlashAggregatorProxy__factory,
} from '../../typechain'

describe('FlashLoan Base', function () {
  let Aggregator,
    aggregator,
    Receiver,
    receiver: InstaFlashReceiver,
    Proxy,
    proxy: InstaFlashAggregatorProxy

  let signer: SignerWithAddress

  const master = '0x911454433E1FACbFfB54E92634440E33e569D389'

  let ABI = ['function initialize()']
  let iface = new ethers.utils.Interface(ABI)
  const data = iface.encodeFunctionData('initialize')

  const DAI = '0x50c5725949A6F0c72E6C4a641F24049A917DB0Cb'
  const WETH = '0x4200000000000000000000000000000000000006'
  const USDBC = '0xd9aAEc86B65D86f6A7B5B1b0c42FFA531710b6CA'

  const ACC_DAI = '0xef6cA7D0ea5D711a393c8626698a804A9ee885c4'
  const ACC_WETH = '0xEE549E4c2558b50b80c0428802d5d83090c22AC4'
  const ACC_USDBC = '0x21F60Db481d7c070329294048A02A27759047A45'

  const dai = ethers.utils.parseUnits('10', 18)
  const usdbc = ethers.utils.parseUnits('10', 6)
  const weth = ethers.utils.parseUnits('1', 18)

  const Dai = ethers.utils.parseUnits('5000', 18)
  const Usdbc = ethers.utils.parseUnits('5000', 6)
  const Weth = ethers.utils.parseUnits('10', 18)

  const _data = '0x'

  let _instaData = '0x'

  beforeEach(async function () {
    ;[signer] = await ethers.getSigners()

    Aggregator = new InstaFlashAggregatorBase__factory(signer)
    aggregator = await Aggregator.deploy()
    await aggregator.deployed()

    Proxy = new InstaFlashAggregatorProxy__factory(signer)
    proxy = await Proxy.deploy(aggregator.address, master, data)
    await proxy.deployed()

    Receiver = new InstaFlashReceiver__factory(signer)
    receiver = await Receiver.deploy(proxy.address)
    await receiver.deployed()

    const token_weth = new ethers.Contract(
      WETH,
      IERC20__factory.abi,
      ethers.provider,
    )

    const token_dai = new ethers.Contract(
      DAI,
      IERC20__factory.abi,
      ethers.provider,
    )

    const token_usdbc = new ethers.Contract(
      USDBC,
      IERC20__factory.abi,
      ethers.provider,
    )

    await hre.network.provider.send('hardhat_setBalance', [
      ACC_DAI,
      ethers.utils.parseEther('10.0').toHexString(),
    ])

    await hre.network.provider.send('hardhat_setBalance', [
      ACC_USDBC,
      ethers.utils.parseEther('10.0').toHexString(),
    ])

    await hre.network.provider.send('hardhat_setBalance', [
      ACC_WETH,
      ethers.utils.parseEther('10.0').toHexString(),
    ])

    await hre.network.provider.send('hardhat_setBalance', [
      proxy.address,
      ethers.utils.parseEther('10.0').toHexString(),
    ])

    await hre.network.provider.request({
      method: 'hardhat_impersonateAccount',
      params: [ACC_USDBC],
    })

    const signer_usdbc = await ethers.getSigner(ACC_USDBC)
    await token_usdbc.connect(signer_usdbc).transfer(receiver.address, usdbc)

    await hre.network.provider.request({
      method: 'hardhat_stopImpersonatingAccount',
      params: [ACC_USDBC],
    })

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

    await hre.network.provider.request({
      method: 'hardhat_impersonateAccount',
      params: [ACC_WETH],
    })

    const signer_weth = await ethers.getSigner(ACC_WETH)
    await token_weth.connect(signer_weth).transfer(receiver.address, weth)

    await hre.network.provider.request({
      method: 'hardhat_stopImpersonatingAccount',
      params: [ACC_WETH],
    })

    _instaData = await ethers.utils.defaultAbiCoder.encode(
      ['tuple(address, address, uint24)'],
      [[DAI, USDBC, '500']],
    )
  })

  describe('Single token', async function () {
    it('Should be able to take flashLoan of a single token from Uniswap', async function () {
      await receiver.flashBorrow([USDBC], [Usdbc], 8, _data, _instaData)
    })
    it('Should be able to take flashLoan of a single token from AAVE V3', async function () {
      await receiver.flashBorrow([USDBC], [Usdbc], 9, _data, _instaData)
    })
    it('Should be able to take flashLoan of weth token from AAVE V3', async function () {
      await receiver.flashBorrow([WETH], [Weth], 9, _data, _instaData)
    })
  })

  describe('Multi token', async function () {

    it('Should be able to take flashLoan of multiple tokens together from Uniswap', async function () {
      await receiver.flashBorrow([DAI, USDBC], [Dai, Usdbc], 8, _data, _instaData)
    })
    it('Should be able to take flashLoan of multiple tokens together from AAVE V3', async function () {
      await receiver.flashBorrow([WETH, USDBC], [Weth, Usdbc], 9, _data, _instaData)
    })
  })
})
