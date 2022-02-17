const hre = require('hardhat')
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
const { ethers } = hre

import {
  InstaFlashloanResolver,
  InstaFlashloanResolver__factory,
} from '../../typechain'

describe('Resolver', function () {
  let Resolver, resolver: InstaFlashloanResolver
  let signer: SignerWithAddress

  const DAI = '0x6b175474e89094c44da98b954eedeac495271d0f'
  const USDT = '0xdac17f958d2ee523a2206206994597c13d831ec7'

  const Dai = ethers.utils.parseUnits('5000', 18)
  const Usdt = ethers.utils.parseUnits('5000', 6)

  beforeEach(async function () {
    ;[signer] = await ethers.getSigners()

    Resolver = new InstaFlashloanResolver__factory(signer)
    resolver = await Resolver.deploy()
    await resolver.deployed()
  })

  it('Should be able to return routes info', async function () {
    console.log((await resolver.getRoutesInfo()).toString())
  })

  it('Should be able to return the best route for flashloan', async function () {
    console.log(
      (await resolver.getBestRoutes([DAI, USDT], [Dai, Usdt])).toString(),
    )
    console.log((await resolver.getBestRoutes([DAI], [Dai])).toString())
  })

  it('Should be able to return all the data for flashloan', async function () {
    console.log((await resolver.getData([DAI, USDT], [Dai, Usdt])).toString())
  })
})
