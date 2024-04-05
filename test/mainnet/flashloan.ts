const hre = require('hardhat')
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
const { ethers } = hre

import {
  AdvancedRouteImplementation,
  AdvancedRouteImplementation__factory,
  InstaFlashAggregator,
  InstaFlashAggregator__factory,
  IERC20__factory,
  IERC20,
  InstaFlashReceiver__factory,
  InstaFlashReceiver,
  InstaFlashAggregatorProxy,
  InstaFlashAggregatorProxy__factory,
} from '../../typechain'

describe('FlashLoan', function () {
  let AdvancedRouteImpl, 
    advancedRouteImpl, 
    Aggregator,
    aggregator,
    Receiver,
    receiver: InstaFlashReceiver,
    Proxy,
    proxy: InstaFlashAggregatorProxy

  let signer: SignerWithAddress

  const master = '0xa8c31E39e40E6765BEdBd83D92D6AA0B33f1CCC5'
  const aaveLendingAddr = '0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9'

  let ABI = ['function initialize(address[],address)']
  let iface = new ethers.utils.Interface(ABI)

  const DAI = '0x6b175474e89094c44da98b954eedeac495271d0f'
  const USDT = '0xdac17f958d2ee523a2206206994597c13d831ec7'
  const WETH = '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2'
  const USDC = '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48'
  const WSTETH = '0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0'
  
  const ACC_DAI = '0x1819EDe3B8411EbC613F3603813Bf42aE09bA5A5'
  const ACC_USDT = '0xF977814e90dA44bFA03b6295A0616a897441aceC'
  const ACC_USDC = '0x51eDF02152EBfb338e03E30d65C15fBf06cc9ECC'
  const ACC_WETH = '0xF04a5cC80B1E94C69B48f5ee68a08CD2F09A7c3E'
  const ACC_WSTETH = '0x04B35d8Eb17729b2C4a4224d07727e2F71283b73'

  const STETH = '0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84'
  const ACC_STETH = '0xFF4606bd3884554CDbDabd9B6e25E2faD4f6fc54'

  const SUSDE = '0x9D39A5DE30e57443BfF2A8307A4256c8797A3497'
  const ACC_SUSDE = '0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb'

  const USDE = '0x4c9EDD5852cd905f086C759E8383e09bff1E68B3'
  const ACC_USDE = '0x8707f238936c12c309bfc2B9959C35828AcFc512'

  const dai = ethers.utils.parseUnits('1000', 18)
  const usdt = ethers.utils.parseUnits('100', 6)
  const usdc = ethers.utils.parseUnits('100', 6)
  const weth = ethers.utils.parseUnits('100', 18)
  const wsteth = ethers.utils.parseUnits('100', 18)
  const Dai = ethers.utils.parseUnits('500', 18)
  const Usdt = ethers.utils.parseUnits('500', 6)
  const Usdc = ethers.utils.parseUnits('500', 6)
  const Weth = ethers.utils.parseUnits('100', 18)
  const Wsteth = ethers.utils.parseUnits('3000', 18)
  const steth = ethers.utils.parseUnits('1', 18)
  const Steth = ethers.utils.parseUnits('100', 18)
  const susde = ethers.utils.parseUnits('100', 18)
  const usde = ethers.utils.parseUnits('100', 18)

  const _data = '0x'

  let _instaData = '0x'
  let proxyContract: any

  beforeEach(async function () {
    ;[signer] = await ethers.getSigners()

    AdvancedRouteImpl = new AdvancedRouteImplementation__factory(signer)
    advancedRouteImpl = await AdvancedRouteImpl.deploy()
    await advancedRouteImpl.deployed()

    const data = iface.encodeFunctionData('initialize', [
      [
        '0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643', // DAI
        '0xf650C3d88D12dB855b8bf7D11Be6C55A4e07dCC9', // USDT
        '0x39AA39c021dfbaE8faC545936693aC917d5E7563', // USDC
        '0xe65cdb6479bac1e22340e4e755fae7e509ecd06c', // AAVE
        '0x6c8c6b02e7b2be14d4fa6022dfd6d75921d90e4e', // BAT
        '0x70e36f6bf80a52b3b46b3af8e106cc0ed743e8e4', // COMP
        '0xface851a4921ce59e912d19329929ce6da6eb0c7', // LINK
        '0x95b4ef2869ebd94beb4eee400a99824bf5dc325b', // MKR
        '0x158079ee67fce2f58472a96584a73c7ab9ac95c1', // REP
        '0x4b0181102a0112a2ef11abee5563bb4a3176c9d7', // SUSHI
        '0x12392f67bdf24fae0af363c24ac620a2f67dad86', // TUSD
        '0x35a18000230da775cac24873d00ff85bccded550', // UNI
        '0xccf4429db6322d5c611ee964527d42e5d685dd6a', // WBTC2
        '0x80a2ae356fc9ef4305676f7a3e2ed04e12c33946', // YFI
        '0xb3319f5d18bc0d84dd1b4825dcde5d5f7266d407', // ZRX
      ],
      master
    ])

    Aggregator = new InstaFlashAggregator__factory(signer)
    aggregator = await Aggregator.deploy()
    await aggregator.deployed()
    console.log('aggregator address: ', aggregator.address)

    Proxy = new InstaFlashAggregatorProxy__factory(signer)
    proxy = await Proxy.deploy(aggregator.address, master, data)
    await proxy.deployed()
    console.log('proxy address: ', proxy.address)

    proxyContract = new ethers.Contract(proxy.address, InstaFlashAggregator__factory.abi, signer)

    Receiver = new InstaFlashReceiver__factory(signer)
    receiver = await Receiver.deploy(proxy.address)
    await receiver.deployed()
    console.log('receiver address: ', receiver.address)

    const token_steth = new ethers.Contract(
      STETH,
      IERC20__factory.abi,
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
      ACC_STETH,
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

    await hre.network.provider.request({
      method: 'hardhat_stopImpersonatingAccount',
      params: [ACC_DAI],
    })

    await hre.network.provider.request({
      method: 'hardhat_impersonateAccount',
      params: [ACC_USDC],
    })

    const token_usdc = new ethers.Contract(
      USDC,
      IERC20__factory.abi,
      ethers.provider,
    )

    const signer_usdc = await ethers.getSigner(ACC_USDC)
    await token_usdc.connect(signer_usdc).transfer(receiver.address, usdc)

    await hre.network.provider.request({
      method: 'hardhat_stopImpersonatingAccount',
      params: [ACC_DAI],
    })

    await hre.network.provider.request({
      method: 'hardhat_impersonateAccount',
      params: [ACC_STETH],
    })

    const signer_steth = await ethers.getSigner(ACC_STETH)
    await token_steth.connect(signer_steth).transfer(receiver.address, steth)
    await token_steth.connect(signer_steth).transfer(proxy.address, steth)

    await hre.network.provider.request({
      method: 'hardhat_stopImpersonatingAccount',
      params: [ACC_STETH],
    })

    const token_wsteth = new ethers.Contract(
            WSTETH,
            IERC20__factory.abi,
            ethers.provider,
          )

    await hre.network.provider.send('hardhat_setBalance', [
            ACC_WSTETH,
            ethers.utils.parseEther('10.0').toHexString(),
          ])

      await hre.network.provider.request({
        method: 'hardhat_impersonateAccount',
        params: [ACC_WSTETH],
      })

      const signer_wsteth = await ethers.getSigner(ACC_WSTETH)
      await token_wsteth.connect(signer_wsteth).transfer(receiver.address, wsteth)
      await token_wsteth.connect(signer_wsteth).transfer(proxy.address, wsteth)

      await hre.network.provider.request({
        method: 'hardhat_stopImpersonatingAccount',
        params: [ACC_WSTETH],
      })

      const token_susde = new ethers.Contract(
        SUSDE,
        IERC20__factory.abi,
        ethers.provider,
      )
  
      await hre.network.provider.send('hardhat_setBalance', [
        ACC_SUSDE,
        ethers.utils.parseEther('10.0').toHexString(),
      ])

      await hre.network.provider.request({
        method: 'hardhat_impersonateAccount',
        params: [ACC_SUSDE],
      })
  
      const signer_susde = await ethers.getSigner(ACC_SUSDE)
      await token_susde.connect(signer_susde).transfer(receiver.address, susde)
      await token_susde.connect(signer_susde).transfer(proxy.address, susde)
      
      await hre.network.provider.request({
        method: 'hardhat_stopImpersonatingAccount',
        params: [ACC_SUSDE],
      })

      const token_usde = new ethers.Contract(
        USDE,
        IERC20__factory.abi,
        ethers.provider,
      )

      await hre.network.provider.send('hardhat_setBalance', [
        ACC_USDE,
        ethers.utils.parseEther('10.0').toHexString(),
      ])

      await hre.network.provider.request({
        method: 'hardhat_impersonateAccount',
        params: [ACC_USDE],
      })

      const signer_usde = await ethers.getSigner(ACC_USDE)
      await token_usde.connect(signer_usde).transfer(receiver.address, usde)
      await token_usde.connect(signer_usde).transfer(proxy.address, usde)

      await hre.network.provider.request({
        method: 'hardhat_stopImpersonatingAccount',
        params: [ACC_USDE],
      })

    await hre.network.provider.request({
      method: 'hardhat_impersonateAccount',
      params: [proxy.address],
    })

    const signer_fla = await ethers.getSigner(proxy.address)
    await token_dai.connect(signer_fla).approve(aaveLendingAddr, 100)

    await hre.network.provider.request({
      method: 'hardhat_stopImpersonatingAccount',
      params: [proxy.address],
    })
    _instaData = '0x'
  })

  describe('Single token', async function () {
    it('Should be able to get routes', async function () {
      console.log('routes: ', await proxyContract.getRoutes());
    })
    it('Should be able to take flashLoan of a single token from AAVE', async function () {
      await receiver.flashBorrow([DAI], [Dai], 1, _data, _instaData)
    })
    it('Should be able to take flashLoan of a single token from MakerDAO', async function () {
      await receiver.flashBorrow([DAI], [Dai], 2, _data, _instaData)
    })
    it('Should be able to take flashLoan of a single token from Compound(MakerDAO)', async function () {
      await receiver.flashBorrow([DAI], [Dai], 3, _data, _instaData)
    })
    it('Should be able to take flashLoan of a single token from AAVE(MakerDAO)', async function () {
      await receiver.flashBorrow([DAI], [Dai], 4, _data, _instaData)
    })
    it('Should be able to take flashLoan of a single token from Balancer', async function () {
      await receiver.flashBorrow([DAI], [Dai], 5, _data, _instaData)
    })
    it('Should be able to take flashLoan of a steth token from Balancer', async function () {
      await receiver.flashBorrow([STETH], [Steth], 5, _data, _instaData)
    })
    it('Should be able to take flashLoan of a single token from Compound(Balancer)', async function () {
      await receiver.flashBorrow([DAI], [Dai], 6, _data, _instaData)
    })
    it('Should be able to take flashLoan of a single token from AAVE(Balancer)', async function () {
      await receiver.flashBorrow([DAI], [Dai], 7, _data, _instaData)
    })
    it('Should be able to take flashLoan of a single token from AAVE V3', async function () {
      await receiver.flashBorrow([DAI], [Dai], 9, _data, _instaData)
    })
    it('Should be able to take flashLoan of a steth token from AAVE V3', async function () {
      await receiver.flashBorrow([STETH], [Steth], 9, _data, _instaData)
    })
    it('Should be able to take flashLoan of a wsteth token from AAVE V3', async function () {
      await receiver.flashBorrow([WSTETH], [Wsteth], 9, _data, _instaData)
    })
    it('Should be able to take flashLoan of a single token from SPARK', async function () {
      await receiver.flashBorrow([DAI], [Dai], 10, _data, _instaData)
    })
    it('Should be able to take flashLoan of a steth token from SPARK', async function () {
      await receiver.flashBorrow([STETH], [Steth], 10, _data, _instaData)
    })
    it('Should be able to take flashLoan of a wsteth token from SPARK', async function () {
      await receiver.flashBorrow([WSTETH], [Wsteth], 10, _data, _instaData)
    })
    it('Should be able to take flashLoan of a susde token from MORPHO', async function () {
      await receiver.flashBorrow([SUSDE], [susde], 11, _data, _instaData)
    })
    it('Should be able to take flashLoan of a usde token from MORPHO', async function () {
      await receiver.flashBorrow([USDE], [usde], 11, _data, _instaData)
    })
  })

  describe('Multi token', async function () {
    beforeEach(async function () {
      const token_usdt = new ethers.Contract(
        USDT,
        IERC20__factory.abi,
        ethers.provider,
      )

      const token_weth = new ethers.Contract(
        WETH,
        IERC20__factory.abi,
        ethers.provider,
      )

      const token_wsteth = new ethers.Contract(
        WSTETH,
        IERC20__factory.abi,
        ethers.provider,
      )

      const token_usdc = new ethers.Contract(
        USDC,
        IERC20__factory.abi,
        ethers.provider,
      )

      await hre.network.provider.send('hardhat_setBalance', [
        ACC_USDT,
        ethers.utils.parseEther('10.0').toHexString(),
      ])

      await hre.network.provider.send('hardhat_setBalance', [
        ACC_WETH,
        ethers.utils.parseEther('10.0').toHexString(),
      ])

      await hre.network.provider.send('hardhat_setBalance', [
        ACC_WSTETH,
        ethers.utils.parseEther('10.0').toHexString(),
      ])

      await hre.network.provider.send('hardhat_setBalance', [
        ACC_USDC,
        ethers.utils.parseEther('10.0').toHexString(),
      ])

      await hre.network.provider.request({
        method: 'hardhat_impersonateAccount',
        params: [ACC_WSTETH],
      })

      const signer_wsteth = await ethers.getSigner(ACC_WSTETH)
      await token_wsteth.connect(signer_wsteth).transfer(receiver.address, wsteth)

      await hre.network.provider.request({
        method: 'hardhat_stopImpersonatingAccount',
        params: [ACC_WSTETH],
      })

      await hre.network.provider.request({
        method: 'hardhat_impersonateAccount',
        params: [ACC_USDT],
      })

      const signer_usdt = await ethers.getSigner(ACC_USDT)
      await token_usdt.connect(signer_usdt).transfer(receiver.address, usdt)

      await hre.network.provider.request({
        method: 'hardhat_stopImpersonatingAccount',
        params: [ACC_USDT],
      })

      await hre.network.provider.request({
        method: 'hardhat_impersonateAccount',
        params: [ACC_USDC],
      })

      const signer_usdc = await ethers.getSigner(ACC_USDC)
      await token_usdc.connect(signer_usdc).transfer(receiver.address, usdc)

      await hre.network.provider.request({
        method: 'hardhat_stopImpersonatingAccount',
        params: [ACC_USDC],
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

      await hre.network.provider.request({
        method: 'hardhat_impersonateAccount',
        params: [proxy.address],
      })

      const signer_fla = await ethers.getSigner(proxy.address)
      await token_usdt.connect(signer_fla).approve(aaveLendingAddr, 100)

      await hre.network.provider.request({
        method: 'hardhat_stopImpersonatingAccount',
        params: [proxy.address],
      })
      _instaData = '0x'
    })
    it('Should be able to take flashLoan of multiple tokens together from AAVE', async function () {
      await receiver.flashBorrow(
        [DAI, USDT, WETH],
        [Dai, Usdt, Weth],
        1,
        _data,
        _instaData,
      )
    })
    it('Should be able to take flashLoan of multiple tokens together from MakerDAO', async function () {
      await receiver.flashBorrow(
        [DAI, USDT, WETH],
        [Dai, Usdt, Weth],
        2,
        _data,
        _instaData,
      )
    })
    it('Should be able to take flashLoan of multiple tokens together from Compound(MakerDAO)', async function () {
      await receiver.flashBorrow(
        [DAI, USDT, WETH],
        [Dai, Usdt, Weth],
        3,
        _data,
        _instaData,
      )
    })
    it('Should be able to take flashLoan of multiple tokens together from AAVE(MakerDAO)', async function () {
      await receiver.flashBorrow(
        [DAI, USDT, WETH],
        [Dai, Usdt, Weth],
        4,
        _data,
        _instaData,
      )
    })
    it('Should be able to take flashLoan of multiple sorted tokens together from Balancer', async function () {
      await receiver.flashBorrow(
        [DAI, USDT, WETH],
        [Dai, Usdt, Weth],
        5,
        _data,
        _instaData,
      )
    })
    it('Should be able to take flashLoan of multiple unsorted tokens together from Balancer', async function () {
      await receiver.flashBorrow(
        [USDT, DAI, WETH],
        [Usdt, Dai, Weth],
        5,
        _data,
        _instaData,
      )
    })
    it('Should be able to take flashLoan of multiple tokens together from Compound(Balancer)', async function () {
      await receiver.flashBorrow(
        [DAI, USDT, WETH],
        [Dai, Usdt, Weth],
        6,
        _data,
        _instaData,
      )
    })
    it('Should be able to take flashLoan of multiple tokens together from AAVE(Balancer)', async function () {
      await receiver.flashBorrow(
        [DAI, WETH],
        [Dai, Weth],
        7,
        _data,
        _instaData,
      )
    })
    it('Should be able to take flashLoan of multiple tokens together from AAVE V3', async function () {
      await receiver.flashBorrow([DAI, USDT, WETH], [Dai, Usdt, Weth], 9, _data, _instaData)
    })
    it('Should be able to take flashLoan of multiple tokens together from SPARK', async function () {
      await receiver.flashBorrow([DAI, WETH, WSTETH], [Dai, Weth, Wsteth], 10, _data, _instaData)
    })
  })
})
