const hre = require("hardhat");
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
const { ethers } = hre;

import {
  InstaFlashloanAggregator,
  InstaFlashloanAggregator__factory,
  InstaFlashloanResolver,
  InstaFlashloanResolver__factory,
} from "../../typechain";

describe("Resolver", function () {
  let Aggregator, aggregator, Resolver, resolver: InstaFlashloanResolver;
  let signer: SignerWithAddress;

  const DAI = "0x6b175474e89094c44da98b954eedeac495271d0f";
  const USDT = "0xdac17f958d2ee523a2206206994597c13d831ec7";

  const Dai = ethers.utils.parseUnits("5000", 18);
  const Usdt = ethers.utils.parseUnits("5000", 6);

  beforeEach(async function () {
    [signer] = await ethers.getSigners();
    Aggregator = new InstaFlashloanAggregator__factory(signer);
    aggregator = await Aggregator.deploy();
    await aggregator.deployed();

    await aggregator.addTokenToCtoken([
      "0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643",
      "0xf650C3d88D12dB855b8bf7D11Be6C55A4e07dCC9",
      "0x39AA39c021dfbaE8faC545936693aC917d5E7563",
    ]); // DAI, USDT, USDC

    Resolver = new InstaFlashloanResolver__factory(signer);
    resolver = await Resolver.deploy(aggregator.address);
    await aggregator.deployed()
  });

  it("Should be able to return routes info", async function () {
    console.log(await resolver.getRoutesInfo());
  });

  it("Should be able to return the best route for flashloan", async function () {
    console.log(await resolver.getBestRoutes([DAI, USDT], [Dai, Usdt]));
    console.log(await resolver.getBestRoutes([DAI], [Dai]));
  });

  
});