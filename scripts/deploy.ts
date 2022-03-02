const hre = require('hardhat')
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
const { ethers } = hre

import {
  InstaFlashAggregatorOptimism,
  InstaFlashAggregatorOptimism__factory,
  InstaFlashAggregatorProxy__factory,
} from '../typechain'

let Aggregator, aggregator: InstaFlashAggregatorOptimism
let proxyAddr = ''

async function scriptRunner() {
  let signer: SignerWithAddress
  let Proxy, proxy

  const master = '0xa9061100d29C3C562a2e2421eb035741C1b42137'
  let ABI = ['function initialize()']
  let iface = new ethers.utils.Interface(ABI)
  const data = iface.encodeFunctionData('initialize')

  ;[signer] = await ethers.getSigners()
  Aggregator = new InstaFlashAggregatorOptimism__factory(signer)
  aggregator = await Aggregator.deploy()
  await aggregator.deployed()

  Proxy = new InstaFlashAggregatorProxy__factory(signer)
  proxy = await Proxy.deploy(aggregator.address, master, data)
  await proxy.deployed()

  proxyAddr = proxy.address

  await hre.run('verify:verify', {
    address: aggregator.address,
    constructorArguments: [],
  })

  console.log((await ethers.provider.getBalance(signer.address)).toString())
}

scriptRunner()
  .then(() => {
    console.log(`Deployed aggregator on ${aggregator.address}`)
    console.log(`Deployed proxy on ${proxyAddr}`)
  })
  .catch((err) => console.error('❌ failed due to error: ', err))
