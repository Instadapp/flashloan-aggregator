const hre = require("hardhat");
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
const { ethers } = hre;

import {
  InstaFlashloanAggregatorAvalanche,
  InstaFlashloanAggregatorAvalanche__factory,
  InstaFlashloanResolverAvalanche,
  InstaFlashloanResolverAvalanche__factory,
  IERC20__factory,
  IERC20,
} from "../../typechain";

describe("Resolver", function () {
  let Aggregator, aggregator, Resolver, resolver: InstaFlashloanResolverAvalanche;
  let signer: SignerWithAddress;

  const DAI = "0xd586e7f844cea2f87f50152665bcbc2c279d8d70";
  const USDT = "0xc7198437980c041c805a1edcba50c1ce5db95118";

  const dai = ethers.utils.parseUnits("10", 18);
  const usdt = ethers.utils.parseUnits("10", 6);
  const Dai = ethers.utils.parseUnits("5000", 18);
  const Usdt = ethers.utils.parseUnits("5000", 6);
  const zeroAddr =
    "0x0000000000000000000000000000000000000000000000000000000000000000";

  beforeEach(async function () {
    [signer] = await ethers.getSigners();
    Aggregator = new InstaFlashloanAggregatorAvalanche__factory(signer);
    aggregator = await Aggregator.deploy();
    await aggregator.deployed();

    Resolver = new InstaFlashloanResolverAvalanche__factory(signer);
    resolver = await Resolver.deploy(aggregator.address);
    await aggregator.deployed()
  });

  it("Should be able to return the best route for flashloan", async function () {
    console.log(await resolver.getBestRoutes([DAI, USDT], [Dai, Usdt]));
  });

  
});
