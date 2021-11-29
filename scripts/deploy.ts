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
  } from "../typechain";

let Aggregator, aggregator: InstaFlashAggregator, Proxy, proxy: InstaFlashAggregatorProxy, Admin, admin: InstaFlashAggregatorAdmin;

const master = '0xa8c31E39e40E6765BEdBd83D92D6AA0B33f1CCC5';

let ABI = [ "function initialize(address[])" ];
let iface = new ethers.utils.Interface(ABI);
const data = iface.encodeFunctionData("initialize", [[
  "0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643", // DAI
  "0xf650C3d88D12dB855b8bf7D11Be6C55A4e07dCC9", // USDT
  "0x39AA39c021dfbaE8faC545936693aC917d5E7563", // USDC
  "0xe65cdb6479bac1e22340e4e755fae7e509ecd06c", // AAVE
  "0x6c8c6b02e7b2be14d4fa6022dfd6d75921d90e4e", // BAT
  "0x70e36f6bf80a52b3b46b3af8e106cc0ed743e8e4", // COMP
  "0xface851a4921ce59e912d19329929ce6da6eb0c7", // LINK
  "0x95b4ef2869ebd94beb4eee400a99824bf5dc325b", // MKR
  "0x158079ee67fce2f58472a96584a73c7ab9ac95c1", // REP
  "0x4b0181102a0112a2ef11abee5563bb4a3176c9d7", // SUSHI
  "0x12392f67bdf24fae0af363c24ac620a2f67dad86", // TUSD
  "0x35a18000230da775cac24873d00ff85bccded550", // UNI
  "0xccf4429db6322d5c611ee964527d42e5d685dd6a", // WBTC2
  "0x80a2ae356fc9ef4305676f7a3e2ed04e12c33946", // YFI
  "0xb3319f5d18bc0d84dd1b4825dcde5d5f7266d407" // ZRX
]])

async function scriptRunner() {
  let signer: SignerWithAddress;
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
}

scriptRunner()
  .then(() => console.log(`Deployed aggregator on ${aggregator.address}, Deployed admin on ${admin.address}`, `Deployed proxy on ${proxy.address}`))
  .catch(err => console.error("❌ failed due to error: ", err));