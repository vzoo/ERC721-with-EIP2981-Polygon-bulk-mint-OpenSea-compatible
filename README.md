# ERC721-with-EIP2981-Polygon-bulk-mint-OpenSea-compatible
OpenZeppelin ERC721 solidity contract compatible with OpenSea - implementing EIP 2981, mint + own limits and bulk mint functionality.

## IMPORTANT NOTICE!

> *This is the successor of our [previous repository](https://github.com/vzoo/ERC721-with-EIP2981-and-reusable-factory-for-OpenSea). Please use this project as we had some serious security concerns about the implementation of OpenSea and it's registry proxy address concept in the reusable-factory repository descended from the Docs of OS. Code in old repo will be kept for reference.*

#### Progress

- ✅ Deployment and Etherscan/Polyscan contract verification with Hardhat tested on Ethereum's Rinkeby and Polygon's Mumbai Testnet
- 🔁 WIP Deployment on Polygon Mainnet

# 1. How to install dependencies

Simply clone the repository and run `npm install`.

# 2. How to set up a new Project

### Prepare .env file
1. Copy the included .env-example file and rename it to .env
2. Edit all required settings in .env file
	1. `NETWORK` = chosen network for deployment, for example `rinkeby`, `maticmum`
	2. `ALCHEMY_KEY` = your Alchemy.io API key (https://dashboard.alchemyapi.io/)
	3. `ETHERSCAN_API_KEY` = your Etherscan API key (https://etherscan.io/)
	4. `POLYGONSCAN_API_KEY` = your Polyscan API key (https://polygonscan.com/)
	5. `ACCOUNT_PRIVATE_KEY` = your **development** Metamask wallet private key (https://metamask.io/) - NEVER SAVE YOUR PRODUCTION PRIVATE KEY IN A CLEAR TEXT FILE!
	6. `PROXY_REGISTRY_ADDRESS` = defaults to OpenSea's proxy registry address
	7. `BASE_URI` = the URI to e.g. your ipfs metadata (https://ipfs.io/)
	8. `CONTRACT_URI` = the URI to your contract's metadata (preferably also on ipfs)

### Edit VZOO.sol
Open VZOO.sol in your favorite editor and edit the following two settings:
1. `NAME`
2. `SYMBOL`

### Edit VZOOERC721.sol
All settings can be changed, but be aware of the implemented business logic.

1. `NUM_COMMON_OPTION`, `NUM_UNCOMMON_OPTION`, `NUM_RARE_OPTION`, `NUM_EPIC_OPTION`, `NUM_LEGENDARY_OPTION` = the amount of NFTs to mint per option, adjust values to your needs
2. `_price` = current sale price per NFT *(can be changed after deployment)*
3. `_saleActive` = default value for the sale state *(can be changed after deployment)*
4. `MAX_SUPPLY` = max amount of NFTs that will exist
5.  `MAX_MINT_TEAM` = max amount of mints allowed for the team
6.  `_maxMintPerAddress` = max amount of mints per wallet address
7.  `_maxNFTPerAddress` = max amount of NFTs allowed to own per wallet
8.  `baseExtension` = metadata base extension (default: "" - empty)

# 3. Handle NFT images and metadata on IPFS

1. Goto https://nft.storage/ and login with an email (magic link) or GitHub
2. Create a new folder in your project directory called `/images/` and a second one called `/metadata/`
3. Put your NFT images and metadata into corresponding folders
4. Run command `npx ipfs-car --pack images --output images.car` to pack your images and `npx ipfs-car --pack metadata --output metadata.car` to pack your metadata in the IPFS compatible `.car` file format (https://github.com/web3-storage/ipfs-car)
5. Go back to the nft.storage tab and upload both `.car` files to IPFS.
6. Note down the CID's for both uploads (e.g. CID for the images `bafybeielduga6juelb1zrfk6o2eguak3txwen3r2dksfjnuaqwexyke41y` and CID for metadata `bafybeibxh2kj6tm1dmotplo5137gqwi6fymmxlwbedeuyuhy53uvgrm2mq`) as they will form the `baseURI` for your NFT contract and token metada and the `image` URI associated with images inside the metadata
7. Update your metadata files with the correct URI, e.g. `https://bafybeielduga6juelb1zrfk6o2eguak3txwen3r2dksfjnuaqwexyke41y.ipfs.nftstorage.link/images/1.jpg`, `https://bafybeielduga6juelb1zrfk6o2eguak3txwen3r2dksfjnuaqwexyke41y.ipfs.nftstorage.link/images/2.jpg`, etc.
8. Set the baseURI in .env file, e.g. `BASE_URI=https://bafybeibxh2kj6tm1dmotplo5137gqwi6fymmxlwbedeuyuhy53uvgrm2mq.ipfs.nftstorage.link/metadata/`

# 4. How to deploy the Contract with Hardhat

## Preparation for Networks

#### Deploy to Ethereum Rinkeby Testnet
In your project's .env file set variable `NETWORK` to `rinkeby`.
```
NETWORK=rinkeby
ALCHEMY_KEY=<YOUR-ALCHEMY-KEY>
ETHERSCAN_API_KEY=<YOUR-ETHERSCAN-API-KEY>
...
```

#### Deploy  to Polygon Mumbai Testnet
In your project's .env file set variable `NETWORK` to `maticmum`.
```
NETWORK=maticmum
ALCHEMY_KEY=<YOUR-ALCHEMY-KEY>
ETHERSCAN_API_KEY=<YOUR-ETHERSCAN-API-KEY>
...
```

## Deployment
If everything is set up correctly, run `npx hardhat deploy` to deploy to the network configured in the `.env` file.

The output should look like this: 
> Contract deployed to address: 0xE224A3331022BEE6cc89216d7B70ec13a4aab8a1

Take a note of the new contract address, we'll need it for the next step.

# 5. Verify contract on Etherscan/Polyscan
Make sure you set up the correct API keys for Etherscan and/or Polyscan - Hardhat will automatically verify the contract based on the chosen network, so you can have both API keys in place at the same time.

To verify the new contract run `npx hardhat verify 0xE224A3331022BEE6cc89216d7B70ec13a4aab8a1 <PROXY_REGISTRY_ADDRESS> <BASE_URI> <CONTRACT_URI> --network maticmum`

For now you need to specify the PROXY_REGISTRY_ADDRESS, BASE_URI and CONTRACT_URI manually, later we'll read the values from the environment variables.

# Additional info
You can also use Ethereums Remix IDE (https://remix.ethereum.org/) for developing and deploying your ERC-721 smart contract.

For convenience and a more efficient verification process you can flatten your solidity files with a simple command.

Run `npx hardhat flatten` to flatten all files, or `npx hardhat flatten FILENAME_HERE.sol` to flatten a single file.

Pay attention to the licenses, there should only be one license description in the whole file - so find and replace all `// SPDX-License-Identifier: <YOUR-LICENSE>` with ` ` and remember to leave one at the top of your flattened file.

Copy the contents of the file into Remix IDE, set the right compiler version (0.8.9) and compile the contract.

Next, choose which network you want to use (select `Injected Web3` as your Environment) and deploy directly from Remix IDE.

Verification of a contract can be done manually on Etherscan/Polyscan or with the Remix IDE (not tested - but simply enable the plugin, enter your API key, plug in the constructor parameters and you should be good to go).

On Polygon's Mumbai Testnet, manual verification (https://mumbai.polygonscan.com/) requires the constructor parameters to be passed as ABI encoded data.

To encode the data:

1. Goto https://abi.hashex.org/ and scroll down to "Or enter your parameters manually"
2. Enter all three required parameters
		1. Type: Address <PROXY_REGISTRY_ADDRESS>
		2. Type: String <BASE_URI>
		3. Type: String <CONTRACT_URI>
3. Copy the output and put it into the appropriate field in the verification form on Polyscan
4. Verify your contract

***GOOD LUCK and have a nice day!***

[VZOO - Protect Endangered Species](https://vzoo.info)

If you have any questions, feel free to join me on our VZOO Discord server: https://discord.gg/revxuTA9RW