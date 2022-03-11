const hre = require('hardhat')
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
const { ethers } = hre

import {
  InstaFlashResolverOptimism,
  InstaFlashResolverOptimism__factory,
} from '../../typechain'

describe('Resolver', function () {
  let Resolver, resolver: InstaFlashResolverOptimism
  let signer: SignerWithAddress

  const DAI = '0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1'
  const USDT = '0x94b008aA00579c1307B0EF2c499aD98a8ce58e58'

  const Dai = ethers.utils.parseUnits('5000', 18)
  const Usdt = ethers.utils.parseUnits('5000', 6)

  beforeEach(async function () {
    ;[signer] = await ethers.getSigners()

    Resolver = new InstaFlashResolverOptimism__factory(signer)
    resolver = await Resolver.deploy()
    await resolver.deployed()
  })

  it('Should be able to return routes info', async function () {
    console.log((await resolver.getRoutes()).toString())
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
