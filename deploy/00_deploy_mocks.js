const {network,ethers} = require("hardhat")
const {developmentChains} =require("../helper-hardhat-config")

const BASE_FEE = "250000000000000000"// premium section in docs// 0.25 is this the premium in LINK
const GAS_PRICE_LINK =  1e9 // link per gas, is this the gas lane? // 0.000000001 LINK per gas

module.exports = async (hre)=>{
    const {getNamedAccounts,deployments} = hre;
    const {deploy,log} = deployments
    const {deployer} = await getNamedAccounts()  // added in module.exports of hardhat.config.js
    const chainId = network.config.chainId

    if (developmentChains.includes(network.name)){
        log("Local network detected. Deploying Mocks....")

        await deploy("VRFCoordinatorV2Mock",{
            from:deployer,
            logs:true,
            args:[BASE_FEE,GAS_PRICE_LINK]
        })

        log("Mocks Deployed!")
        log("----------------------------------------------------------")
        log("You are deploying to a local network, you'll need a local network running to interact")
        log(
            "Please run `yarn hardhat console --network localhost` to interact with the deployed smart contracts!"
        )
        log("----------------------------------------------------------")
    }

}
module.exports.tags = ["all", "mocks"]