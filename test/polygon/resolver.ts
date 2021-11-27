const hre = require("hardhat");
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
const { ethers } = hre;

import {
  InstaFlashAggregatorPolygon,
  InstaFlashAggregatorPolygon__factory,
  InstaFlashloanResolverPolygon,
  InstaFlashloanResolverPolygon__factory,
} from "../../typechain";

describe("Resolver", function () {
  let Aggregator, aggregator, Resolver, resolver: InstaFlashloanResolverPolygon;
  let signer: SignerWithAddress;

  const DAI = "0x8f3cf7ad23cd3cadbd9735aff958023239c6a063";
  const USDT = "0xc2132d05d31c914a87c6611c10748aeb04b58e8f";

  const Dai = ethers.utils.parseUnits("5000", 18);
  const Usdt = ethers.utils.parseUnits("5000", 6);

  beforeEach(async function () {
    [signer] = await ethers.getSigners();
    Aggregator = new InstaFlashAggregatorPolygon__factory(signer);
    aggregator = await Aggregator.deploy();
    await aggregator.deployed();

    Resolver = new InstaFlashloanResolverPolygon__factory(signer);
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
