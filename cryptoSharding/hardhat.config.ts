import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-ethers";
import "@nomicfoundation/hardhat-chai-matchers";
import "@nomicfoundation/hardhat-network-helpers";
import "@nomicfoundation/hardhat-verify";
import "hardhat-gas-reporter";
import * as dotenv from "dotenv";

dotenv.config();

const sepoliaRPC = process.env.SEPOLIA_RPC;
const sepoliaAccount = process.env.PRIVATE_KEY;
const polyAccount = process.env.POLY_PK;
const verifyKey = process.env.ETHERSCAN_API_KEY;

const config: HardhatUserConfig = {
  solidity: "0.8.24",

  networks: {
    sepolia: {
      url: sepoliaRPC,
      accounts: [`0x${sepoliaAccount}`],
    },
    polygon: {
      url: process.env.POLYGON_RPC,
      accounts: [`0x${polyAccount}`],
    },
  },

  etherscan: {
    apiKey: {
      polygon: process.env.POLYGON_API_KEY || "",
      sepolia: verifyKey,
    },
  },
};

export default config;
