const hre = require("hardhat")
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
const { ethers } = hre

import {
  InstaFlashAggregatorArbitrum__factory,
  InstaFlashResolverArbitrum,
  InstaFlashResolverArbitrum__factory,
} from "../../typechain"

describe("Resolver", function () {
  let Aggregator,
    aggregator;
  let Resolver, resolver: InstaFlashResolverArbitrum
  let signer: SignerWithAddress
  let proxyAddr = '0x1f882522DF99820dF8e586b6df8bAae2b91a782d'
  let admin = '0x82D57efa1cE59A0cA3492e189c72B360c7a1Dcdd'

  const USDC = "0xff970a61a04b1ca14834a43f5de4533ebddb5cc8"
  const USDT = "0xfd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9"

  const Usdc = ethers.utils.parseUnits("5000", 6)
  const Usdt = ethers.utils.parseUnits("5000", 6)

  beforeEach(async function () {
    [signer] = await ethers.getSigners()

    Aggregator = new InstaFlashAggregatorArbitrum__factory(signer);
    aggregator = await Aggregator.deploy();
    await aggregator.deployed();
    console.log("Aggregator deployed at: ", aggregator.address);

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

    let tx = await proxy.connect(impersonateAcc).upgradeTo(aggregator.address)
    let receipt = tx.wait()

    let addr = await proxy.connect(impersonateAcc).callStatic.implementation()
    console.log("Implementation at: ", addr)

    Resolver = new InstaFlashResolverArbitrum__factory(signer)
    resolver = await Resolver.deploy()
    await resolver.deployed()
    console.log("Resolver deployed at: ", resolver.address)
  })

  it("Should be able to return routes info", async function () {
    console.log("Routes info-")
    console.log((await resolver.getRoutes()).toString())
  })

  it("Should be able to return the best route for flashloan", async function () {
    console.log("Best route for flashloan (USDC, USDT)-")
    console.log(
      (await resolver.getBestRoutes([USDC, USDT], [Usdc, Usdt])).toString()
    )
  })

  it("Should be able to return all the data for flashloan", async function () {
    console.log("All data for (USDC, USDT)-")
    console.log(
      (await resolver.getData([USDC, USDT], [Usdc, Usdt])).toString()
    )
  })
})
