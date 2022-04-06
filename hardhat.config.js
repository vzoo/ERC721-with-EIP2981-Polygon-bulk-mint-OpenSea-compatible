/**
 * @type import('hardhat/config').HardhatUserConfig
 */

require('dotenv').config();
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");
require("./scripts/deploy.js");
require("./scripts/mint.js");

const {
  ALCHEMY_KEY,
  ACCOUNT_PRIVATE_KEY,
  ETHERSCAN_API_KEY,
  POLYGONSCAN_API_KEY,
  NETWORK
} = process.env;

module.exports = {
  solidity: {
    version: "0.8.9",
    settings: {
      optimizer: {
        enabled: true,
        runs: 500,
      },
    },
  },
  defaultNetwork: `${NETWORK}`,
  networks: {
    hardhat: {},
    rinkeby: {
      url: `https://eth-rinkeby.alchemyapi.io/v2/${ALCHEMY_KEY}`,
      accounts: [`0x${ACCOUNT_PRIVATE_KEY}`]
    },
    ethereum: {
      chainId: 1,
      url: `https://eth-mainnet.alchemyapi.io/v2/${ALCHEMY_KEY}`,
      accounts: [`0x${ACCOUNT_PRIVATE_KEY}`]
    },
    maticmum: {
      chainId: 80001,
      url: `https://polygon-mumbai.g.alchemy.com/v2/${ALCHEMY_KEY}`,
      accounts: [`0x${ACCOUNT_PRIVATE_KEY}`]
    },
    matic: {
      chainId: 137,
      url: `https://rpc-mumbai.maticvigil.com/${ALCHEMY_KEY}`,
      accounts: [`0x${ACCOUNT_PRIVATE_KEY}`]
    },
  },
  etherscan: {
    apiKey: {
      // ethereum
      mainnet: ETHERSCAN_API_KEY,
      rinkeby: ETHERSCAN_API_KEY,
      // polygon
      polygon: POLYGONSCAN_API_KEY,
      polygonMumbai: POLYGONSCAN_API_KEY,
    }
  }
}