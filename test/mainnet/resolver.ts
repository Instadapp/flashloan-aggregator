const hre = require("hardhat");
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
const { ethers } = hre;

import {
  InstaFlashAggregator,
  InstaFlashAggregator__factory,
  InstaFlashAggregatorProxy,
  InstaFlashAggregatorProxy__factory,
  InstaFlashAggregatorAdmin,
  InstaFlashAggregatorAdmin__factory,
  InstaFlashloanResolver,
  InstaFlashloanResolver__factory
} from "../../typechain";

describe("Resolver", function () {
  let Aggregator, aggregator, Resolver, resolver: InstaFlashloanResolver, Proxy, proxy, Admin, admin;
  let signer: SignerWithAddress;

  const master = '0xa9061100d29C3C562a2e2421eb035741C1b42137';

  let ABI = [ "function initialize(address[] memory)" ];
  let iface = new ethers.utils.Interface(ABI);
  const data = iface.encodeFunctionData("initialize", [[
    "0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643",
    "0xf650C3d88D12dB855b8bf7D11Be6C55A4e07dCC9",
    "0x39AA39c021dfbaE8faC545936693aC917d5E7563",
  ]]) // DAI, USDT, USDC

  const DAI = "0x6b175474e89094c44da98b954eedeac495271d0f";
  const USDT = "0xdac17f958d2ee523a2206206994597c13d831ec7";

  const Dai = ethers.utils.parseUnits("5000", 18);
  const Usdt = ethers.utils.parseUnits("5000", 6);

  beforeEach(async function () {
    [signer] = await ethers.getSigners();

    Aggregator = new InstaFlashAggregator__factory(signer);
    aggregator = await Aggregator.deploy();
    await aggregator.deployed();

    Admin = new InstaFlashAggregatorAdmin__factory(signer);
    admin = await Admin.deploy(master);
    await admin.deployed();

    Proxy = new InstaFlashAggregatorProxy__factory(signer);
    proxy = await Proxy.deploy(aggregator.address, admin.address, data);
    await proxy.deployed();

    Resolver = new InstaFlashloanResolver__factory(signer);
    resolver = await Resolver.deploy(proxy.address);
    await aggregator.deployed()
  });

  it("Should be able to return routes info", async function () {
    console.log((await resolver.getRoutesInfo()).toString());
  });

  it("Should be able to return the best route for flashloan", async function () {
    console.log((await resolver.getBestRoutes([DAI, USDT], [Dai, Usdt])).toString());
    console.log((await resolver.getBestRoutes([DAI], [Dai])).toString());
  });

  it("Should be able to return all the data for flashloan", async function () {
    console.log((await resolver.getData([DAI, USDT], [Dai, Usdt])).toString());
  });
  
});
