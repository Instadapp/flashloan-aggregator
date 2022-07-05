const hre = require('hardhat')
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
const { ethers } = hre

import {
  InstaFlashAggregatorFantom__factory,
  InstaFlashAggregatorProxy__factory,
  InstaFlashloanResolverFantom,
  InstaFlashloanResolverFantom__factory,
  AaveV3Resolver__factory,
  AaveV3Resolver,
  FLAImplementationFantom__factory,
  FLAResolver,
  FLAResolver__factory,
  IERC20__factory,
} from '../../typechain'

describe('Resolver', function () {
  let AaveV3, aaveV3, FLA, fla;
  let Resolver, resolver: InstaFlashloanResolverFantom
  let signer: SignerWithAddress

  const proxy = "0x22ed23Cc6EFf065AfDb7D5fF0CBf6886fd19aee1";

  const DAI = '0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E'
  const USDC = '0x04068DA6C83AFCFA0e13ba15A6696662335D5B75'

  const Dai = ethers.utils.parseUnits('5000', 18)
  const Usdc = ethers.utils.parseUnits('5000', 6)

  const ACC_DAI = '0x1c664Bafc646510684Ba1588798c67fe22a8c7cf'
  const ACC_USDC = '0x1c664Bafc646510684Ba1588798c67fe22a8c7cf'

  const master = '0xa9061100d29C3C562a2e2421eb035741C1b42137'

  let ABI = ['function initialize(address,address,address)']
  let iface = new ethers.utils.Interface(ABI)

  beforeEach(async function () {
    ;[signer] = await ethers.getSigners()

    AaveV3 = new AaveV3Resolver__factory(signer)
    aaveV3 = await AaveV3.deploy()
    await aaveV3.deployed()
    // console.log('aaveV3 at: ', aaveV3.address)

    FLA = new FLAResolver__factory(signer)
    fla = await FLA.deploy()
    await fla.deployed()
    // console.log('fla at: ', fla.address)

    Resolver = new InstaFlashloanResolverFantom__factory(signer)
    resolver = await Resolver.deploy()
    await resolver.deployed()
    console.log("resolver deployed at: ", resolver.address)

    // await resolver.connect(signer).initialize(["9", "10"],[aaveV3.address, fla.address])

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
      proxy,
      ethers.utils.parseEther('10.0').toHexString(),
    ])

    await hre.network.provider.request({
      method: 'hardhat_impersonateAccount',
      params: [ACC_DAI],
    })

    const signer_dai = await ethers.getSigner(ACC_DAI)
    await token_dai.connect(signer_dai).transfer(proxy, Dai)

    await hre.network.provider.request({
      method: 'hardhat_stopImpersonatingAccount',
      params: [ACC_DAI],
    })

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
    await token.connect(signer_usdc).transfer(proxy, Usdc)

    await hre.network.provider.request({
      method: 'hardhat_stopImpersonatingAccount',
      params: [ACC_USDC],
    })
  })

  it('Should be able to return routes info', async function () {
    console.log((await resolver.getRoutesInfo()).toString())
  })

  it('Should be able to return the best route for flashloan', async function () {
    console.log(
      (await resolver.getBestRoutes([DAI, USDC], [Dai, Usdc])).toString(),
    )
  })

  it('Should be able to return all the data for flashloan', async function () {
    console.log((await resolver.getData([DAI, USDC], [Dai, Usdc])).toString())
  })
})
