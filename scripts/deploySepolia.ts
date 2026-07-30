const hre = require('hardhat')
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
const { ethers } = hre

import {
  InstaFlashAggregatorSepolia,
  InstaFlashAggregatorSepolia__factory,
  InstaFlashAggregatorProxy__factory,
  InstaFlashAggregatorProxyAdmin__factory
} from '../typechain'

let Aggregator, aggregator: InstaFlashAggregatorSepolia
let proxyAddr = ''

async function scriptRunner() {
  let signer: SignerWithAddress
  let Proxy, proxy, Admin, admin

  const master = '0xe73D1f06C2CA358Ab48a3011e06e83F79F8A26cD'
  const data = '0x'; // Empty data since no initialize function

  [signer] = await ethers.getSigners()
  Aggregator = new InstaFlashAggregatorSepolia__factory(signer)
  aggregator = await Aggregator.deploy()
  await aggregator.deployed()
  console.log('Sepolia Aggregator deployed to: ', aggregator.address)

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
    contract: 'contracts/aggregator/sepolia/flashloan/main.sol:InstaFlashAggregatorSepolia',
  })

  console.log((await ethers.provider.getBalance(signer.address)).toString())
}

scriptRunner()
  .then(() => {
    console.log(`Deployed Sepolia aggregator on ${aggregator.address}`)
    console.log(`Deployed proxy on ${proxyAddr}`)
  })
  .catch((err) => console.error('❌ failed due to error: ', err))