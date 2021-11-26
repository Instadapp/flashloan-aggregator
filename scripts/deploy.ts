const hre = require("hardhat");
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
const { ethers } = hre;

import {
    InstaFlashloanAggregatorPolygon,
    InstaFlashloanAggregatorPolygon__factory,
    InstaFlashloanResolverPolygon,
    InstaFlashloanResolverPolygon__factory,
  } from "../typechain";

let Aggregator, aggregator: InstaFlashloanAggregatorPolygon, Resolver, resolver: InstaFlashloanResolverPolygon;
async function testRunner() {
    let signer: SignerWithAddress;
    [signer] = await ethers.getSigners();

    Aggregator = new InstaFlashloanAggregatorPolygon__factory(signer);
    aggregator = await Aggregator.deploy();
    await aggregator.deployed();

    Resolver = new InstaFlashloanResolverPolygon__factory(signer);
    resolver = await Resolver.deploy(aggregator.address);
    await resolver.deployed()
}

testRunner()
  .then(() => console.log(`Deployed aggregator on ${aggregator.address}, Deployed resolver on ${resolver.address}`))
  .catch(err => console.error("❌ failed due to error: ", err));