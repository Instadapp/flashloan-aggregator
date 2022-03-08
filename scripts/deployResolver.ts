const hre = require('hardhat')
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
const { ethers } = hre

import {
    InstaFlashloanResolverPolygon,
    InstaFlashloanResolverPolygon__factory,
} from '../typechain'

let Resolver, resolver: InstaFlashloanResolverPolygon

async function scriptRunner() {
  let signer: SignerWithAddress
  ;[signer] = await ethers.getSigners()

  console.log((await ethers.provider.getBalance(signer.address)).toString())
  console.log(signer.address)

  Resolver = new InstaFlashloanResolverPolygon__factory(signer)
  resolver = await Resolver.deploy()
  await resolver.deployed()

  await hre.run('verify:verify', {
    address: resolver.address,
    constructorArguments: [],
  })

  console.log((await ethers.provider.getBalance(signer.address)).toString())
}

scriptRunner()
  .then(() => console.log(`Deployed resolver on ${resolver.address}`))
  .catch((err) => console.error('❌ failed due to error: ', err))
