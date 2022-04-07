const {
    task
} = require("hardhat/config");
const {
    getContract,
    getEnvVariable
} = require("./helpers");
const fetch = require("node-fetch");

task("mintOptionTo", "Bulk mints an option from the NFT contract to an address")
    .addParam("msgValue", "Amount send via the transaction")
    .addParam("toAddress", "The address to receive a token")
    .addParam("optionId", "The address to receive a token")
    .setAction(async function (taskArguments, hre) {
        const contract = await getContract(getEnvVariable("CONTRACT_NAME"), hre);
        const transactionResponse = await contract.mintTo(taskArguments.msgValue, taskArguments.toAddress, taskArguments.optionId, {
            gasLimit: 500_000,
        });
        console.log(`Transaction Hash: ${transactionResponse.hash}`);
    });

task("toggleSaleState", "Toggles the sale state of a contract address")
    .setAction(async function (taskArguments, hre) {
        const contract = await getContract(getEnvVariable("CONTRACT_NAME"), hre);
        const transactionResponse = await contract.toggleSaleState({
            gasLimit: 500_000,
        });
        console.log(`Transaction Hash: ${transactionResponse.hash}`);
    });

task("setSecAllowMsgSenderOverride", "Allows or denies overriding _msgSender")
    .addParam("allowed", "Whether to allow (true, Default) or deny (false) using _msgSender override")
    .setAction(async function (taskArguments, hre) {
        const contract = await getContract(getEnvVariable("CONTRACT_NAME"), hre);
        const transactionResponse = await contract.setSecAllowMsgSenderOverride(taskArguments.allowed, {
            gasLimit: 500_000,
        });
        console.log(`Transaction Hash: ${transactionResponse.hash}`);
    });

task("setSecAllowIsApprovedForAll", "Allows or denies overriding isApprovedForAll")
    .addParam("allowed", "Whether to allow (true, Default) or deny (false) using isApprovedForAll override")
    .setAction(async function (taskArguments, hre) {
        const contract = await getContract(getEnvVariable("CONTRACT_NAME"), hre);
        const transactionResponse = await contract.setSecAllowIsApprovedForAll(taskArguments.allowed, {
            gasLimit: 500_000,
        });
        console.log(`Transaction Hash: ${transactionResponse.hash}`);
    });

task("set-base-token-uri", "Sets the base token URI for the deployed smart contract")
    .addParam("baseUrl", "The base of the tokenURI endpoint to set")
    .setAction(async function (taskArguments, hre) {
        const contract = await getContract(getEnvVariable("CONTRACT_NAME"), hre);
        const transactionResponse = await contract.setBaseTokenURI(taskArguments.baseUrl, {
            gasLimit: 500_000,
        });
        console.log(`Transaction Hash: ${transactionResponse.hash}`);
    });


task("token-uri", "Fetches the token metadata for the given token ID")
    .addParam("tokenId", "The tokenID to fetch metadata for")
    .setAction(async function (taskArguments, hre) {
        const contract = await getContract(getEnvVariable("CONTRACT_NAME"), hre);
        const response = await contract.tokenURI(taskArguments.tokenId, {
            gasLimit: 500_000,
        });

        const metadata_url = response;
        console.log(`Metadata URL: ${metadata_url}`);

        const metadata = await fetch(metadata_url).then(res => res.json());
        console.log(`Metadata fetch response: ${JSON.stringify(metadata, null, 2)}`);
    });