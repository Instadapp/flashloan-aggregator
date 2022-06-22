const hre = require('hardhat')
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
const { ethers } = hre

import {
  InstaFlashAggregatorFantom,
  InstaFlashAggregatorFantom__factory,
  FlashAggregatorFantom__factory,
  IERC20__factory,
  IERC20,
  InstaFlashReceiver__factory,
  InstaFlashReceiver,
  InstaFlashAggregatorProxy,
  InstaFlashAggregatorProxy__factory,
  AaveImplementationFantom,
  AaveImplementationFantom__factory,
  FLAImplementationFantom__factory,
  FLAImplementationFantom
} from '../../typechain'

describe('FlashLoan', function () {
  let Aggregator,
    aggregator,
    Receiver,
    receiver: InstaFlashReceiver,
    Proxy,
    proxy: InstaFlashAggregatorProxy,
    ImplAave,
    implAave,
    ImplFLA,
    implFLA: FLAImplementationFantom,
    proxyNew: any;

  let signer: SignerWithAddress

  const master = '0xa9061100d29C3C562a2e2421eb035741C1b42137'
  let masterSigner: any

  let ABI = ['function initialize(address,address)']
  let iface = new ethers.utils.Interface(ABI)

  const DAI = '0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E'
  const USDC = '0x04068DA6C83AFCFA0e13ba15A6696662335D5B75'
  const ACC_DAI = '0x1c664Bafc646510684Ba1588798c67fe22a8c7cf'
  const ACC_USDC = '0x1c664Bafc646510684Ba1588798c67fe22a8c7cf'

  const dai = ethers.utils.parseUnits('10', 18)
  const usdc = ethers.utils.parseUnits('10', 6)
  const Dai = ethers.utils.parseUnits('5000', 18)
  const Usdc = ethers.utils.parseUnits('5000', 6)

  const zeroAddr =
    '0x0000000000000000000000000000000000000000000000000000000000000000'

    let _instaData = ''


  beforeEach(async function () {
    await hre.network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          forking: {
            //@ts-ignore
            jsonRpcUrl: hre.config.networks.hardhat.forking.url,
            blockNumber: 36529195
          }
        }
      ]
    });

    ;[signer] = await ethers.getSigners()
    Aggregator = new InstaFlashAggregatorFantom__factory(signer)
    aggregator = await Aggregator.deploy()
    await aggregator.deployed()

    ImplAave = new AaveImplementationFantom__factory(signer)
    implAave = await ImplAave.deploy()
    await implAave.deployed()

    ImplFLA = new FLAImplementationFantom__factory(signer)
    implFLA = await ImplFLA.deploy()
    await implFLA.deployed()

    const data = iface.encodeFunctionData('initialize', [signer.address, implAave.address])

    Proxy = new InstaFlashAggregatorProxy__factory(signer)
    proxy = await Proxy.deploy(aggregator.address, master, data)
    await proxy.deployed()

    Receiver = new InstaFlashReceiver__factory(signer)
    receiver = await Receiver.deploy(proxy.address)
    await receiver.deployed()

    proxyNew = new ethers.Contract(
      proxy.address,
      FlashAggregatorFantom__factory.abi,
      ethers.provider,
    )

    const token_dai = new ethers.Contract(
      DAI,
      IERC20__factory.abi,
      ethers.provider,
    )

    await hre.network.provider.send('hardhat_setBalance', [
      ACC_DAI,
      ethers.utils.parseEther('10.0').toHexString(),
    ])
    await hre.network.provider.send('hardhat_setBalance', [
      proxy.address,
      ethers.utils.parseEther('10.0').toHexString(),
    ])

    await hre.network.provider.request({
      method: 'hardhat_impersonateAccount',
      params: [ACC_DAI],
    })

    const signer_dai = await ethers.getSigner(ACC_DAI)
    await token_dai.connect(signer_dai).transfer(receiver.address, dai)
    await token_dai.connect(signer_dai).transfer(proxy.address, Dai)

    await hre.network.provider.request({
      method: 'hardhat_stopImpersonatingAccount',
      params: [ACC_DAI],
    })

    _instaData = '0x'
  })

  describe('Single token', async function () {
    it('Should be able to take flashLoan of a single token from AAVE V3', async function () {
      await receiver.flashBorrow([DAI], [Dai], 9, zeroAddr,_instaData)
    })
    it('Should add new route and take flashloan', async function () {
      await proxyNew.connect(signer).addNewRoutes(['10'],[implFLA.address]);
      await receiver.flashBorrow([DAI], [Dai], 10, zeroAddr, _instaData);
    })
  })

  describe('Multi token', async function () {
    beforeEach(async function () {
      const token = new ethers.Contract(
        USDC,
        IERC20__factory.abi,
        ethers.provider,
      )

      await hre.network.provider.send('hardhat_setBalance', [
        ACC_USDC,
        ethers.utils.parseEther('10.0').toHexString(),
      ])

      await hre.network.provider.request({
        method: 'hardhat_impersonateAccount',
        params: [ACC_USDC],
      })

      const signer_usdc = await ethers.getSigner(ACC_USDC)
      await token.connect(signer_usdc).transfer(receiver.address, usdc)
      await token.connect(signer_usdc).transfer(proxy.address, Usdc)

      await hre.network.provider.request({
        method: 'hardhat_stopImpersonatingAccount',
        params: [ACC_USDC],
      })
      _instaData = '0x'
    })
    it('Should be able to take flashLoan of multiple tokens together from AAVE V3', async function () {
      await receiver.flashBorrow([DAI, USDC], [Dai, Usdc], 9, zeroAddr, _instaData )
    })
    it('Should add new route and take flashloan and take flashLoan of multiple tokens from FLA', async function () {
      await proxyNew.connect(signer).addNewRoutes(['10'],[implFLA.address]);
      await receiver.flashBorrow([DAI, USDC], [Dai, Usdc], 10, zeroAddr, _instaData )
    })
  })
})
