const hre = require("hardhat");
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
const { ethers } = hre;

import {
  InstaFlashAggregatorAvalanche,
  InstaFlashAggregatorAvalanche__factory,
  InstaFlashloanResolverAvalanche,
  InstaFlashloanResolverAvalanche__factory,
  InstaFlashAggregatorProxy,
  InstaFlashAggregatorProxy__factory,
  InstaFlashAggregatorAdmin,
  InstaFlashAggregatorAdmin__factory,
} from "../../typechain";

describe("Resolver", function () {
  let Aggregator, aggregator, Resolver, resolver: InstaFlashloanResolverAvalanche, Proxy, proxy, Admin, admin;
  let signer: SignerWithAddress;

  const master = '0xa9061100d29C3C562a2e2421eb035741C1b42137';

  let ABI = [ "function initialize()" ];
  let iface = new ethers.utils.Interface(ABI);
  const data = iface.encodeFunctionData("initialize")

  const DAI = "0xd586e7f844cea2f87f50152665bcbc2c279d8d70";
  const USDT = "0xc7198437980c041c805a1edcba50c1ce5db95118";

  const Dai = ethers.utils.parseUnits("5000", 18);
  const Usdt = ethers.utils.parseUnits("5000", 6);

  beforeEach(async function () {
    [signer] = await ethers.getSigners();

    Aggregator = new InstaFlashAggregatorAvalanche__factory(signer);
    aggregator = await Aggregator.deploy();
    await aggregator.deployed();

    Admin = new InstaFlashAggregatorAdmin__factory(signer);
    admin = await Admin.deploy(master);
    await admin.deployed();

    Proxy = new InstaFlashAggregatorProxy__factory(signer);
    proxy = await Proxy.deploy(aggregator.address, admin.address, data);
    await proxy.deployed();

    Resolver = new InstaFlashloanResolverAvalanche__factory(signer);
    resolver = await Resolver.deploy(aggregator.address);
    await aggregator.deployed()
  });

  it("Should be able to return routes info", async function () {
    console.log((await resolver.getRoutesInfo()).toString());
  });

  it("Should be able to return the best route for flashloan", async function () {
    console.log((await resolver.getBestRoutes([DAI, USDT], [Dai, Usdt])).toString());
  });

  it("Should be able to return all the data for flashloan", async function () {
    console.log((await resolver.getData([DAI, USDT], [Dai, Usdt])).toString());
  });
  
});
