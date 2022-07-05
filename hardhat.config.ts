import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-etherscan";
import '@openzeppelin/hardhat-upgrades';
import "@typechain/hardhat";
import "hardhat-gas-reporter";
import "solidity-coverage";

import "./tasks/accounts";
import "./tasks/clean";

import { resolve } from "path";
import { config as dotenvConfig } from "dotenv";
import { HardhatUserConfig } from "hardhat/config";
import { NetworkUserConfig } from "hardhat/types";

dotenvConfig({ path: resolve(__dirname, "./.env") });

const chainIds = {
  ganache: 1337,
  goerli: 5,
  hardhat: 31337,
  kovan: 42,
  mainnet: 1,
  rinkeby: 4,
  ropsten: 3,
  avalanche: 43114,
  polygon: 137,
  optimism: 10,
  fantom: 250,
};

// Ensure that we have all the environment variables we need.
const mnemonic = process.env.MNEMONIC;
if (!mnemonic) {
  throw new Error("Please set your MNEMONIC in a .env file");
}

const alchemyApiKey = process.env.ALCHEMY_API_KEY;
if (!alchemyApiKey) {
  throw new Error("Please set your ALCHEMY_ETH_API_KEY in a .env file");
}

function createTestnetConfig(network: keyof typeof chainIds): NetworkUserConfig {
  const url: string = "https://eth-" + network + ".alchemyapi.io/v2/" + alchemyApiKey;
  return {
    accounts: {
      count: 10,
      initialIndex: 0,
      mnemonic,
      path: "m/44'/60'/0'/0",
    },
    chainId: chainIds[network],
    url,
  };
}

function getNetworkUrl(networkType: string) {
  //console.log(process.env);
  if (networkType === "avalanche") return "https://api.avax.network/ext/bc/C/rpc";
  else if (networkType === "polygon") return `https://polygon-mainnet.g.alchemy.com/v2/${alchemyApiKey}`;
  else if (networkType === "arbitrum") return `https://arb-mainnet.g.alchemy.com/v2/${alchemyApiKey}`;
  else if (networkType === "optimism") return `https://opt-mainnet.g.alchemy.com/v2/${alchemyApiKey}`;
  else if (networkType === "fantom") return `https://rpc.ankr.com/fantom`;
  else return `https://eth-mainnet.alchemyapi.io/v2/${alchemyApiKey}`;
}

function getBlockNumber(networkType: string) {
  if (networkType === "avalanche") return 7675580;
  else if (networkType === "polygon") return 25941254;
  else if (networkType === "arbitrum") return 7719792;
  else if (networkType === "optimism") return 4346343;
  else if (networkType === "fantom") return 42070000;
  else return 14456907;
}

const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  gasReporter: {
    currency: "USD",
    enabled: process.env.REPORT_GAS ? true : false,
    excludeContracts: [],
    src: "./contracts",
  },
  networks: {
    hardhat: {
      accounts: {
        mnemonic,
      },
      chainId: chainIds.hardhat,
      forking: {
        url: String(getNetworkUrl(String(process.env.networkType))),
        blockNumber: getBlockNumber(String(process.env.networkType)),
      },
    },
    goerli: createTestnetConfig("goerli"),
    kovan: createTestnetConfig("kovan"),
    rinkeby: createTestnetConfig("rinkeby"),
    ropsten: createTestnetConfig("ropsten"),
    // hardhat: {
    //   forking: {
    //     url: `https://eth-mainnet.alchemyapi.io/v2/${alchemyApiKey}`,
    //   },
    //   gasPrice: 151101000000,
    // },
    mainnet: {
      url: `https://eth-mainnet.alchemyapi.io/v2/${alchemyApiKey}`,
      chainId: 1,
      gasPrice: 52101000000,
      accounts: [`0x${process.env.PRIVATE_KEY}`]
    },
    avalanche_mainnet: {
      url: 'https://api.avax.network/ext/bc/C/rpc',
      chainId: 43114,
      accounts: [`0x${process.env.PRIVATE_KEY}`],
      gasPrice: 40110000000,
    },
    arbitrum_mainnet: {
      url: `https://arb-mainnet.g.alchemy.com/v2/${alchemyApiKey}`,
      chainId: 42161,
      accounts: [`0x${process.env.PRIVATE_KEY}`],
      gasPrice: 1500000000
    },
    polygon_mainnet: {
      url: `https://polygon-mainnet.g.alchemy.com/v2/${alchemyApiKey}`,
      chainId: 137,
      accounts: [`0x${process.env.PRIVATE_KEY}`],
      gasPrice: 70000000000,
    },
    optimism_mainnet: {
      url: `https://opt-mainnet.g.alchemy.com/v2/${alchemyApiKey}`,
      chainId: 10,
      accounts: [`0x${process.env.PRIVATE_KEY}`],
      gasPrice: 1000000,
    },
    fantom_mainnet: {
      url: `https://rpc.ankr.com/fantom`,
      chainId: 250,
      accounts: [`0x${process.env.PRIVATE_KEY}`],
      gasPrice: 210011000000,
    },
  },
  paths: {
    artifacts: "./artifacts",
    cache: "./cache",
    sources: "./contracts",
    tests: "./test",
  },
  solidity: {
    compilers: [
      {
        version: "0.8.4",
        settings: {
          metadata: {
            bytecodeHash: "none",
          },
          optimizer: {
            enabled: true,
            runs: 800,
          },
        },
      },
      {
        version: "0.7.6",
        settings: {
          optimizer: {
            enabled: true,
            runs: 800,
          },
        },
      },
    ],
  },
  typechain: {
    outDir: "typechain",
    target: "ethers-v5",
  },
  mocha: {
    timeout: 10000000 * 1000, // 10M sec
  },
  etherscan: {
    apiKey: `${process.env.SCAN_API_KEY}`
  }
};

export default config;