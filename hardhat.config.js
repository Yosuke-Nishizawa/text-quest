require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();
require("hardhat-abi-exporter");
require("@nomicfoundation/hardhat-verify");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.18",
  networks: {
    hardhat: {},
    goerli: {
      url: `https://eth-goerli.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY}`,
      accounts: [process.env.PRIVATE_KEY],
    },
  },
  abiExporter: {
    path: "./contracts/abi",
    runOnCompile: true,
    clear: true,
    pretty: true,
  },
  etherscan: {
    apiKey: process.env.ETHERS_SCAN_API_KEY,
  },
};
