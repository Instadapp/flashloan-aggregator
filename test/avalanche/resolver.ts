const hre = require('hardhat')
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
const { ethers } = hre

import {
  InstaFlashloanResolverAvalanche,
  InstaFlashloanResolverAvalanche__factory,
} from '../../typechain'

describe('Resolver', function () {

  let Resolver, resolver: InstaFlashloanResolverAvalanche
  let signer: SignerWithAddress
  let admin = '0x7b0990a249a215c9a88EBeC3849920e29725F2d0'
  // let newImplementation = '0x304371cb3196caCD51dBF427D2bFcd6b58EA712B'
  let proxyAddr = '0x2b65731A085B55DBe6c7DcC8D717Ac36c00F6d19'

  const DAI = '0xd586e7f844cea2f87f50152665bcbc2c279d8d70'
  const USDTE = '0xc7198437980c041c805a1edcba50c1ce5db95118'
  const USDT = '0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7'

  const Dai = ethers.utils.parseUnits('5000', 18)
  const Usdte = ethers.utils.parseUnits('5000', 6)
  const Usdt = ethers.utils.parseUnits('5000', 6)

  it("should set up", async function () {
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
    ]);


    let impersonateAcc = await ethers.getSigner(admin);

    let tx = await proxy.connect(impersonateAcc).upgradeTo('0x304371cb3196caCD51dBF427D2bFcd6b58EA712B');
    let receipt = tx.wait();


    Resolver = new InstaFlashloanResolverAvalanche__factory(signer)
    resolver = await Resolver.deploy()
    await resolver.deployed()
    console.log("Resolver deployed at: ", resolver.address);

  })

  it('Should be able to return routes info', async function () {
    console.log("Routes info-");
    console.log((await resolver.getRoutesInfo()).toString())
  })

  it('Should be able to return the best route for flashloan', async function () {
    console.log("Best route for flashloan (DAI, USDTE)-");
    console.log(await resolver.getBestRoutes([DAI, USDTE], [Dai, Usdte]));
  })

  it('Should be able to return the best route for flashloan', async function () {
    console.log("Best route for flashloan (DAI, USDT)-");
    console.log(((await resolver.getBestRoutes([DAI, USDT], [Dai, Usdt])).toString()))
  })

  it('Should be able to return all the data for flashloan', async function () {
    console.log("All data for (DAI, USDTE)-");
    console.log((await resolver.getData([DAI, USDTE], [Dai, Usdte])).toString())
  })

  it('Should be able to return all the data for flashloan', async function () {
    console.log("All data for (DAI, USDT)-");
    console.log((await resolver.getData([DAI, USDT], [Dai, Usdt])).toString())
  })
})
