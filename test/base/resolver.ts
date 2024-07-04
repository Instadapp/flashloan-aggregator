const hre = require('hardhat')
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
const { ethers } = hre

import {
    InstaFlashResolverBase,
    InstaFlashResolverBase__factory,
} from '../../typechain'

describe('Resolver', function () {
  let Resolver, resolver: InstaFlashResolverBase
  let signer: SignerWithAddress

  const DAI = '0xd9aAEc86B65D86f6A7B5B1b0c42FFA531710b6CA'
  const USDBC = '0xdac17f958d2ee523a2206206994597c13d831ec7'

  const Dai = ethers.utils.parseUnits('5000', 18)
  const Usdbc = ethers.utils.parseUnits('5000', 6)

  beforeEach(async function () {
    ;[signer] = await ethers.getSigners()

    Resolver = new InstaFlashResolverBase__factory(signer)
    resolver = await Resolver.deploy()
    await resolver.deployed()
  })

  it('Should be able to return routes info', async function () {
    console.log((await resolver.getRoutes()).toString())
  })

  it('Should be able to return the best route for flashloan', async function () {
    console.log(
      (await resolver.getBestRoutes([DAI, USDBC], [Dai, Usdbc])).toString(),
    )
    console.log((await resolver.getBestRoutes([DAI], [Dai])).toString())
  })

  it('Should be able to return all the data for flashloan', async function () {
    console.log((await resolver.getData([DAI, USDBC], [Dai, Usdbc])).toString())
  })
})
