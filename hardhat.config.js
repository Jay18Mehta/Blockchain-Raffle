require("@nomicfoundation/hardhat-toolbox");
require("hardhat-deploy")
require("@nomiclabs/hardhat-ethers")

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    compilers:[{version:"0.8.12"},{version:"0.8.4"}]
  },
  namedAccounts:{
    deployer:{
      default:0
    },
    player:{
      default:1
    }
  },
  defaultNetwork:"hardhat",
  //to deploy on others networks other than hardhat run following script
  //npx hardhat run scripts/deploy.js --network ganache
  networks:{
    ganache:{
      url:"http://127.0.0.1:7545",
      accounts:["0xd7f67da7f7ed53601e314f6c7aceb2c1e0ded78d489997cb833e574296050210"],
      chainId:1337
    },
    //for hardhat localhost node
    localhost:{
      url:"http://127.0.0.1:8545/",
      //accounts:taken care by hardhat
      chainId:31337,
    },
    sepolia: {
      url: "https://rpc.sepolia.org",
      accounts: ["a782c6ec47d008d4b4f0965848e252d515d8456de688e7a0d567fb04ec20886e"],
      chainId: 11155111,
      blockConfirmations: 6,  // not needed
  },
  },
};
