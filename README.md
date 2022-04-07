# ERC721-with-EIP2981-Polygon-bulk-mint-OpenSea-compatible
OpenZeppelin ERC721 solidity contract compatible with OpenSea - implementing EIP 2981, mint amount + owning limits, sane security defaults and bulk mint functionality.

## Progress

- ✅ Deployment and Etherscan/Polyscan contract verification with Hardhat tested on Ethereum's Rinkeby and Polygon's Mumbai Testnet
- 🔁 WIP Deployment on Polygon Mainnet

---

# 1. How to install required dependencies

Simply clone or fork the repository and run `npm install`.


I assume you already have your NFT images and metadata ready for deployment.
If you want to know how to render NFTs and create appropriate metadata using Unreal Engine 5, you can find me in our Discord (https://discord.gg/revxuTA9RW).

# 2. How to set up a new Project

### Prepare .env file
1. Copy the included .env-example file and rename it to .env
2. Edit all required variables in .env file
	1. `NETWORK` = chosen network for deployment, for example `rinkeby`, `maticmum`
	2. `ALCHEMY_KEY` = your Alchemy.io API key (https://dashboard.alchemyapi.io/)
	3. `ETHERSCAN_API_KEY` = your Etherscan API key (https://etherscan.io/)
	4. `POLYGONSCAN_API_KEY` = your Polygonscan API key (https://polygonscan.com/)
	5. `ACCOUNT_PRIVATE_KEY` = your **development** Metamask wallet private key (https://metamask.io/) - **NEVER SAVE IMPORTANT PRIVATE KEYS IN A CLEAR TEXT FILE!**
	6. `PROXY_REGISTRY_ADDRESS` = OpenSea's proxy registry address (Default: Mumbai Testnet - 0x58807baD0B376efc12F5AD86aAc70E78ed67deaE)
	7. `BASE_URI` = the URI to e.g. your IPFS metadata (https://ipfs.io/)
	8. `CONTRACT_URI` = the URI to your contract's metadata (preferably also hosted on IPFS)

### Edit VZOO.sol
Open VZOO.sol in your favorite editor and change the following two variables:
1. `NAME`
2. `SYMBOL`

### Edit VZOOERC721.sol
All settings can be changed, but be aware of the implemented business logic.

1. `NUM_COMMON_OPTION`, `NUM_UNCOMMON_OPTION`, `NUM_RARE_OPTION`, `NUM_EPIC_OPTION`, `NUM_LEGENDARY_OPTION` = the amount of NFTs to mint per option, adjust values to your needs
2. `MAX_SUPPLY` = max amount of NFTs that will exist
3. `_price` = current sale price for one NFT *(can be changed after deployment)*
4.  `_maxMintTeam` = max amount of mints allowed for the team *(can be changed after deployment)*
5.  `_maxMintPerAddress` = max amount of mints per wallet address *(can be changed after deployment)*
6.  `_maxNFTPerAddress` = max amount of NFTs allowed to own per wallet *(can be changed after deployment)*
7.  `baseExtension` = metadata base extension (Default: "" - empty) *(can be changed after deployment)*
8. `_saleActive` = default value for the sale state *(can be changed after deployment)*
9. `_secAllowMsgSenderOverride` = Security switch to allow/deny override of _msgSender for marketplaces (Default: true) *(can be changed after deployment)*
10. `_secAllowIsApprovedForAll` = Security switch to allow/deny override of isApprovedForAll for marketplaces (Default: true) *(can be changed after deployment)*
11.  `_receiver` = *Set in constructor*, required by EIP-2981: NFT Royalty Standard (Default: owner) *(can be changed after deployment)*
12. `_feeNumerator` = *Set in constructor*, required by EIP-2981: NFT Royalty Standard (Default: 1000) *(can be changed after deployment)*

# 3. Store NFT images and metadata on IPFS

1. Goto https://nft.storage/ and login with an email (magic link) or GitHub
2. Create a new folder in your project directory called `/images/` and a second one called `/metadata/`
3. Put your NFT images and metadata into the corresponding folders
4. Run command `npx ipfs-car --pack images --output images.car` to pack your images and `npx ipfs-car --pack metadata --output metadata.car` to pack your metadata in the IPFS compatible `.car` file format (https://github.com/web3-storage/ipfs-car)
5. Go back to the nft.storage tab and upload both `.car` files to IPFS.
6. Note down the CID's for both uploads (example CID for images `bafybeielduga6juelb1zrfk6o2eguak3txwen3r2dksfjnuaqwexyke41y` and for metadata `bafybeibxh2kj6tm1dmotplo5137gqwi6fymmxlwbedeuyuhy53uvgrm2mq`) as they will form the `baseURI` for your NFT contract and token metadata + the `image` URI associated with your NFT images inside the metadata
7. Update your metadata files with the correct URI, e.g. `"image" : "https://bafybeielduga6juelb1zrfk6o2eguak3txwen3r2dksfjnuaqwexyke41y.ipfs.nftstorage.link/images/1.jpg"`, `"image" : "https://bafybeielduga6juelb1zrfk6o2eguak3txwen3r2dksfjnuaqwexyke41y.ipfs.nftstorage.link/images/2.jpg"`, etc.
8. Set the baseURI in .env file, e.g. `BASE_URI=https://bafybeibxh2kj6tm1dmotplo5137gqwi6fymmxlwbedeuyuhy53uvgrm2mq.ipfs.nftstorage.link/metadata/`

Refer to this link for more information on using metadata: [metadata-standards](https://docs.opensea.io/docs/metadata-standards)

# 4. How to deploy the Contract with Hardhat

## Preparation for target network

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

## Sale
Call `toggleSaleState()` on the contract to enable public sale - and call `saleState()` afterwards to verify the result.

# 5. Verify contract on Etherscan/Polyscan
Make sure you set up the correct API keys for Etherscan and/or Polyscan - Hardhat will automatically verify the contract based on the chosen network, so you can have both API keys in place at the same time.

To verify the new contract run `npx hardhat verify 0xE224A3331022BEE6cc89216d7B70ec13a4aab8a1 <PROXY_REGISTRY_ADDRESS> <BASE_URI> <CONTRACT_URI> --network maticmum`

For now you need to specify the PROXY_REGISTRY_ADDRESS, BASE_URI and CONTRACT_URI manually, later we'll read the values from the environment variables.

# Additional info
You can also use Ethereums Remix IDE (https://remix.ethereum.org/) for developing and deploying your ERC-721 smart contract.

For convenience and a more efficient verification process you can flatten your solidity files with a simple command.

Run `npx hardhat flatten` to flatten all files, or `npx hardhat flatten FILENAME_HERE.sol` to flatten a single file.

Pay attention to the SPDX-License identifiers, there should be only one license description in the whole file - so find and replace all `// SPDX-License-Identifier: <YOUR-LICENSE>` with ` `, but remember to leave one at the top of your flattened file.

Copy all content of the flattened file into a new file created in Remix IDE, set the correct compiler version (0.8.9) and compile the contract.

Next, choose which network you want to use (select `Injected Web3` as your environment) and deploy directly from Remix IDE.

Verification of a contract can be done manually on Etherscan/Polyscan or directly in Remix (not tested - but simply enable the plugin, enter your API key, plug in the constructor parameters and you should be good to go).

Manual contract verifications on most Block Explorers (e.g. https://mumbai.polygonscan.com/) require the constructor parameters to be passed as ABI encoded data.

To encode the data:

1. Goto https://abi.hashex.org/ - scroll down to "Or enter your parameters manually" and click on "Add argument"
2. Add all three required arguments
		1. Type: `Address` <PROXY_REGISTRY_ADDRESS>
		2. Type: `String` <BASE_URI>
		3. Type: `String` <CONTRACT_URI>
3. Copy the output and put it into the appropriate field in the verification form on the Block Explorer
4. Verify your contract

If you have any problem with Hardhat not compiling or verifying correctly, try to run `npx hardhat clean` and compile+deploy+verify again.

***GOOD LUCK and have a nice day!***

[VZOO - Protect Endangered Species](https://vzoo.info)

If you have any questions, feel free to join me on our VZOO Discord server: https://discord.gg/revxuTA9RW