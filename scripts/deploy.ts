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

  const master = '0xD4E5e20eF32b4750d4cD185a8E970b89851E7775'
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

  await hre.run('verify:verify', {
    address: "0x84E6b05A089d5677A702cF61dc14335b4bE5b282",
    constructorArguments: ["0xDAa3F68f0033d8ad252e0a53b402943221705714",master,data],
    contracts: 'contracts/proxy/proxy.sol:InstaFlashAggregatorProxy'
  })

  console.log((await ethers.provider.getBalance(signer.address)).toString())
}

scriptRunner()
  .then(() => {
    console.log(`Deployed aggregator on ${aggregator.address}`)
    console.log(`Deployed proxy on ${proxyAddr}`)
  })
  .catch((err) => console.error('❌ failed due to error: ', err))
