const hre = require("hardhat");
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
const { ethers } = hre;

import {
  InstaFlashloanResolverAvalanche,
  InstaFlashloanResolverAvalanche__factory,
} from "../../typechain";

describe("Resolver", function () {
  let Resolver, resolver: InstaFlashloanResolverAvalanche;
  let signer: SignerWithAddress;

  const DAI = "0xd586e7f844cea2f87f50152665bcbc2c279d8d70";
  const USDT = "0xc7198437980c041c805a1edcba50c1ce5db95118";

  const Dai = ethers.utils.parseUnits("5000", 18);
  const Usdt = ethers.utils.parseUnits("5000", 6);

  beforeEach(async function () {
    [signer] = await ethers.getSigners();

    Resolver = new InstaFlashloanResolverAvalanche__factory(signer);
    resolver = await Resolver.deploy();
    await resolver.deployed()
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
