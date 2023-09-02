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
  const USDC = '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48'

  const Dai = ethers.utils.parseUnits('5000', 18)
  const Usdt = ethers.utils.parseUnits('5000', 6)

  const Steth = ethers.utils.parseUnits('500', 18)
  const Usdc = ethers.utils.parseUnits('5000', 6)

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
    console.log('steth and usdc: ',
      (await resolver.getBestRoutes([STETH, USDC], [Steth, Usdc])).toString(),
    )
    console.log('steth: ', (await resolver.getBestRoutes([STETH], [Steth])).toString())
  })

  it('Should be able to return all the data for flashloan', async function () {
    console.log((await resolver.getData([STETH, USDC], [Steth, Usdc])).toString())
  })
})
