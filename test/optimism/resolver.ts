const hre = require('hardhat')
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
const { ethers } = hre

import {
  InstaFlashResolverOptimism,
  InstaFlashResolverOptimism__factory,
  InstaFlashAggregatorArbitrum__factory
} from '../../typechain'

describe('Resolver', function () {
  let Resolver, resolver: InstaFlashResolverOptimism
  let signer: SignerWithAddress
  let proxyAddr = '0x84E6b05A089d5677A702cF61dc14335b4bE5b282'
  let admin = '0xD4E5e20eF32b4750d4cD185a8E970b89851E7775'
  let newImplementation = '0x03f821d24DfD8ECbeB4bf31B9374B8087E9a406c'

  const DAI = '0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1'
  const USDT = '0x94b008aA00579c1307B0EF2c499aD98a8ce58e58'

  const Dai = ethers.utils.parseUnits('5000', 18)
  const Usdt = ethers.utils.parseUnits('5000', 6)

  beforeEach(async function () {
    ;[signer] = await ethers.getSigners()

    let proxy = new hre.ethers.Contract(
      proxyAddr,
      [{"inputs":[{"internalType":"address","name":"_logic","type":"address"},{"internalType":"address","name":"admin_","type":"address"},{"internalType":"bytes","name":"_data","type":"bytes"}],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"previousAdmin","type":"address"},{"indexed":false,"internalType":"address","name":"newAdmin","type":"address"}],"name":"AdminChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"beacon","type":"address"}],"name":"BeaconUpgraded","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"implementation","type":"address"}],"name":"Upgraded","type":"event"},{"stateMutability":"payable","type":"fallback"},{"inputs":[],"name":"admin","outputs":[{"internalType":"address","name":"admin_","type":"address"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"newAdmin","type":"address"}],"name":"changeAdmin","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"implementation","outputs":[{"internalType":"address","name":"implementation_","type":"address"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"newImplementation","type":"address"}],"name":"upgradeTo","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"newImplementation","type":"address"},{"internalType":"bytes","name":"data","type":"bytes"}],"name":"upgradeToAndCall","outputs":[],"stateMutability":"payable","type":"function"},{"stateMutability":"payable","type":"receive"}],
      ethers.provider,
    )

    await hre.network.provider.request({
      method: 'hardhat_impersonateAccount',
      params: [admin],
    })

    await hre.network.provider.send("hardhat_setBalance", [
      admin,
      "0x1935A74CFEBFA4",
    ])

    let impersonateAcc = await ethers.getSigner(admin)

    let tx = await proxy.connect(impersonateAcc).upgradeTo(newImplementation)
    let receipt = tx.wait()

    let addr = await proxy.connect(impersonateAcc).callStatic.implementation()
    console.log("Implementation at: ", addr)

    Resolver = new InstaFlashResolverOptimism__factory(signer)
    resolver = await Resolver.deploy()
    await resolver.deployed()
    console.log("Resolver deployed at: ", resolver.address)
  })

  it('Should be able to return routes info', async function () {
    console.log("Routes info-")
    console.log((await resolver.getRoutes()).toString())
  })

  it('Should be able to return the best route for flashloan', async function () {
    console.log("Best route for flashloan (DAI, USDT)-")
    console.log(
      (await resolver.getBestRoutes([DAI, USDT], [Dai, Usdt])).toString(),
    )
  })

  it('Should be able to return all the data for flashloan', async function () {
    console.log("All data for (DAI, USDT)-")
    console.log((await resolver.getData([DAI, USDT], [Dai, Usdt])).toString())
  })
})
