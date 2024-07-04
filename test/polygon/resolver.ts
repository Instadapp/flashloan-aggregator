const hre = require('hardhat')
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
const { ethers } = hre

import {
  InstaFlashResolverPolygon,
  InstaFlashResolverPolygon__factory,
} from '../../typechain'

// import {
//   InstaFlashAggregatorPolygon__factory,
//   InstaFlashAggregatorProxy__factory,
// } from '../../typechain'

describe('Resolver', function () {
  // let Aggregator,
  //   aggregator,
  //   Proxy,
  //   proxy
  let Resolver, resolver: InstaFlashResolverPolygon
  let signer: SignerWithAddress

  // const master = '0xa9061100d29C3C562a2e2421eb035741C1b42137'

  // let ABI = ['function initialize()']
  // let iface = new ethers.utils.Interface(ABI)
  // const data = iface.encodeFunctionData('initialize')

  const DAI = '0x8f3cf7ad23cd3cadbd9735aff958023239c6a063'
  const USDT = '0xc2132d05d31c914a87c6611c10748aeb04b58e8f'

  const Dai = ethers.utils.parseUnits('5000', 18)
  const Usdt = ethers.utils.parseUnits('5000', 6)

  beforeEach(async function () {
    ;[signer] = await ethers.getSigners()

    // Aggregator = new InstaFlashAggregatorPolygon__factory(signer)
    // aggregator = await Aggregator.deploy()
    // await aggregator.deployed()
    // console.log('Aggregator at: ',aggregator.address);

    // Proxy = new InstaFlashAggregatorProxy__factory(signer)
    // proxy = await Proxy.deploy(aggregator.address, master, data)
    // await proxy.deployed()
    // console.log('Proxy at: ',proxy.address)

    Resolver = new InstaFlashResolverPolygon__factory(signer)
    resolver = await Resolver.deploy()
    await resolver.deployed()
    console.log("Resolver deployed at: ", resolver.address);

    // await resolver.initialize(proxy.address);

  })

  it('Should be able to return routes info', async function () {
    console.log("Routes available: ", (await resolver.getRoutes()).toString())
  })

  it('Should be able to return the best route for flashloan', async function () {
    console.log(
      (await resolver.getBestRoutes([DAI, USDT], [Dai, Usdt])).toString(),
    )
  })

  it('Should be able to return all the data for flashloan', async function () {
    console.log((await resolver.getData([DAI, USDT], [Dai, Usdt])).toString())
  })
})
