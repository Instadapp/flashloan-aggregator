const hre = require('hardhat')
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
const { ethers } = hre

import {
  InstaFlashResolver,
  InstaFlashResolver__factory,
} from '../../typechain'

describe('Resolver', function () {
  let Resolver, resolver: InstaFlashResolver
  let signer: SignerWithAddress

  const DAI = '0x6b175474e89094c44da98b954eedeac495271d0f'
  const USDT = '0xdac17f958d2ee523a2206206994597c13d831ec7'

  const STETH = '0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84'
  const LINK = '0x514910771af9ca656af840dff83e8264ecf986ca'
  const USDC = '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48'

  const WSTETH = '0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0'
  const USDE = '0x4c9EDD5852cd905f086C759E8383e09bff1E68B3'
  const SUSDE = '0x9D39A5DE30e57443BfF2A8307A4256c8797A3497'

  const Wsteth = ethers.utils.parseUnits('30000', 18)

  const Dai = ethers.utils.parseUnits('5000', 18)
  const Usdt = ethers.utils.parseUnits('5000', 6)
  const Link = ethers.utils.parseUnits('100', 18)

  const Steth = ethers.utils.parseUnits('500', 18)
  const Usdc = ethers.utils.parseUnits('5000', 6)
  const Usde = ethers.utils.parseUnits('5000', 18)
  const Susde = ethers.utils.parseUnits('5000', 18)

  beforeEach(async function () {
    ;[signer] = await ethers.getSigners()

    Resolver = new InstaFlashResolver__factory(signer)
    resolver = await Resolver.deploy()
    await resolver.deployed()
  })

  it('Should be able to return routes info', async function () {
    console.log((await resolver.getRoutesInfo()).toString())
  })

  it('Should be able to return the best route for flashloan', async function () {
    console.log('link and steth: ',
      (await resolver.getBestRoutes([LINK, STETH], [Link, Steth])).toString(),
    )
    console.log('link: ', (await resolver.getBestRoutes([LINK], [Link])).toString())
    console.log('steth: ', (await resolver.getBestRoutes([STETH], [Steth])).toString())
    console.log('wsteth: ', (await resolver.getBestRoutes([WSTETH], [Wsteth])).toString())
    console.log('usde: ', (await resolver.getBestRoutes([USDE], [Usde])).toString())
    console.log('susde: ', (await resolver.getBestRoutes([SUSDE], [Susde])).toString())
  })

  it('Should be able to return all the data for flashloan', async function () {
    console.log((await resolver.getData([STETH, USDC], [Steth, Usdc])).toString())
  })
})
