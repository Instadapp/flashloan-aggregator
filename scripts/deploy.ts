const hre = require('hardhat')
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
const { ethers } = hre

import {
  InstaFlashAggregatorBase,
  InstaFlashAggregatorBase__factory,
  InstaFlashAggregatorProxy__factory,
  InstaFlashAggregatorProxyAdmin__factory
} from '../typechain'

let Aggregator, aggregator: InstaFlashAggregatorBase
let proxyAddr = ''

async function scriptRunner() {
  let signer: SignerWithAddress
  let Proxy, proxy, Admin, admin

  const master = '0x911454433E1FACbFfB54E92634440E33e569D389'
  const ABI = ['function initialize()']
  const iface = new ethers.utils.Interface(ABI)
  const data = iface.encodeFunctionData('initialize')

  ;[signer] = await ethers.getSigners()
  Aggregator = new InstaFlashAggregatorBase__factory(signer)
  aggregator = await Aggregator.deploy()
  await aggregator.deployed()
  console.log('Aggregator deployed to: ', aggregator.address)

  Admin = new InstaFlashAggregatorProxyAdmin__factory(signer)
  admin = await Admin.deploy(master)
  await admin.deployed()
  console.log('Admin deployed to: ', admin.address)

  Proxy = new InstaFlashAggregatorProxy__factory(signer)
  proxy = await Proxy.deploy(aggregator.address, admin.address, data)
  await proxy.deployed()
  console.log('Proxy deployed to: ', proxy.address)

  proxyAddr = proxy.address

  await hre.run('verify:verify', {
    address: aggregator.address,
    constructorArguments: [],
  })

  await hre.run('verify:verify', {
    address: proxyAddr,
    constructorArguments: [
      aggregator.address,
      admin.address,
      data,
    ],
    contract: 'contracts/proxy/proxy.sol:InstaFlashAggregatorProxy',
  })

  await hre.run('verify:verify', {
    address: admin.address,
    constructorArguments: [
      master
    ],
    contract: 'contracts/proxy/proxyAdmin.sol:InstaFlashAggregatorProxyAdmin',
  })

  await hre.run('verify:verify', {
    address: aggregator.address,
    constructorArguments: [],
    contract: 'contracts/aggregator/base/flashloan/main.sol:InstaFlashAggregatorBase',
  })

  console.log((await ethers.provider.getBalance(signer.address)).toString())
}

scriptRunner()
  .then(() => {
    console.log(`Deployed aggregator on ${aggregator.address}`)
    console.log(`Deployed proxy on ${proxyAddr}`)
  })
  .catch((err) => console.error('❌ failed due to error: ', err))
