const {
    task
} = require("hardhat/config");
const {
    getAccount,
    getEnvVariable
} = require("./helpers");

task("check-balance", "Prints out the balance of your account").setAction(async function (taskArguments, hre) {
    const account = getAccount();
    console.log(`Account balance for ${account.address}: ${await account.getBalance()}`);
});

task("deploy", "Deploys the NFT contract")
    .setAction(async function (taskArguments, hre) {
        const nftContractFactory = await hre.ethers.getContractFactory("VZOO", getAccount());
        const nft = await nftContractFactory.deploy(getEnvVariable("PROXY_REGISTRY_ADDRESS"), getEnvVariable("BASE_URI"), getEnvVariable("CONTRACT_URI"));
        console.log(`Contract deployed to address: ${nft.address}`);
    });