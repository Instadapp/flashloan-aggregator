const hre = require('hardhat')
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
const { ethers } = hre

import {
  InstaFlashAggregatorFantom__factory,
  InstaFlashAggregatorProxy__factory,
  AaveImplementationFantom__factory,
  InstaFlashloanResolverFantom,
  InstaFlashloanResolverFantom__factory,
} from '../../typechain'

describe('Resolver', function () {
  let Resolver, resolver: InstaFlashloanResolverFantom
  let signer: SignerWithAddress

  const DAI = '0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E'
  const USDC = '0x04068DA6C83AFCFA0e13ba15A6696662335D5B75'

  const Dai = ethers.utils.parseUnits('5000', 18)
  const Usdc = ethers.utils.parseUnits('5000', 6)

  const master = '0xa9061100d29C3C562a2e2421eb035741C1b42137'

  // let ABI = ['function initialize(address)']
  // let iface = new ethers.utils.Interface(ABI)

  beforeEach(async function () {
    ;[signer] = await ethers.getSigners()
    // let Aggregator,
    // aggregator,
    // Proxy,
    // proxy,
    // ImplAave,
    // implAave;

    // Aggregator = new InstaFlashAggregatorFantom__factory(signer)
    // aggregator = await Aggregator.deploy()
    // await aggregator.deployed()
    // console.log("aggregator deployed at: ", aggregator.address)

    // ImplAave = new AaveImplementationFantom__factory(signer)
    // implAave = await ImplAave.deploy()
    // await implAave.deployed()
    // console.log("implAave deployed at: ", implAave.address)

    // const data = iface.encodeFunctionData('initialize', [implAave.address])

    // Proxy = new InstaFlashAggregatorProxy__factory(signer)
    // proxy = await Proxy.deploy(aggregator.address, master, data)
    // await proxy.deployed()
    // console.log('Proxy at: ',proxy.address)

    Resolver = new InstaFlashloanResolverFantom__factory(signer)
    resolver = await Resolver.deploy()
    await resolver.deployed()
    console.log("resolver deployed at: ", resolver.address)

    // await resolver.initialize(proxy.address)
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