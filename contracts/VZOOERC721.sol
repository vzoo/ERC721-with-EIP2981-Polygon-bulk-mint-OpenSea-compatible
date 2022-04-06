// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./common/meta-transactions/ContentMixin.sol";
import "./common/meta-transactions/NativeMetaTransaction.sol";

/// @title VZOO contract
/// @dev Extends ERC721 Non-Fungible Token Standard basic implementation
abstract contract VZOOERC721 is
    ERC721Enumerable,
    ERC721URIStorage,
    ERC721Royalty,
    ContextMixin,
    NativeMetaTransaction,
    Pausable,
    Ownable
{
    using Counters for Counters.Counter;
    using Strings for uint256;

    /// Can be changed after deployment.
    /// @dev Base URI for token metadata.
    string private baseURI;

    /// Can be changed after deployment.
    /// @dev Base URI for contract metadata.
    string private baseContractURI;

    /// @dev Five different options for minting.
    uint256 NUM_OPTIONS = 5;

    uint256 COMMON_OPTION = 0;
    uint256 UNCOMMON_OPTION = 1;
    uint256 RARE_OPTION = 2;
    uint256 EPIC_OPTION = 3;
    uint256 LEGENDARY_OPTION = 4;

    uint256 NUM_COMMON_OPTION = 1;
    uint256 NUM_UNCOMMON_OPTION = 3;
    uint256 NUM_RARE_OPTION = 9;
    uint256 NUM_EPIC_OPTION = 18;
    uint256 NUM_LEGENDARY_OPTION = 36;

    uint256 private _price = 0.1 ether;
    bool private _saleActive = false;

    /// @dev Enforce the existence of 10.000 VZOO Collection #1 NFTs.
    uint256 public MAX_SUPPLY = 10000;

    /// @dev Allowed NFT mints for the VZOO Core Team.
    uint256 private MAX_MINT_TEAM = 200;

    /// Can be changed after deployment.
    /// @dev Allowed NFT mints per wallet address.
    uint256 private _maxMintPerAddress = 36;

    /// Can be changed after deployment.
    /// @dev Allowed amount of NFTs a wallet address can own.
    uint256 private _maxNFTPerAddress = 36;

    /// Can be changed after deployment.
    /// @dev Base extension for metadata (e.g. ".json", default is "").
    string public baseExtension = "";

    /// Can be changed after deployment.
    /// @dev Keeps track of wallet addresses that took part in minting our NFTs.
    mapping(address => uint256) public addressMintedBalance;

    /// Track nextTokenId instead of currentTokenId to save users on gas costs.
    /// @dev Relies on the OpenZeppelin Counter to keep track of the next available ID
    Counters.Counter private _nextTokenId;

    /// Can be changed after deployment.
    /// @dev Receiver wallet address and fee numerator for royalties (EIP2981).
    address private _receiver;
    uint96 private _feeNumerator;

    address public _proxyRegistryAddress;
    string private _name;
    string private _symbol;

    constructor(
        string memory _nameERC721,
        string memory _symbolERC721,
        address _initProxyRegistryAddress,
        string memory _initBaseURI,
        string memory _initContractURI
    ) ERC721(_nameERC721, _symbolERC721) {
        _initializeEIP712(_nameERC721);
        setProxyRegistryAddress(_initProxyRegistryAddress);
        setBaseURI(_initBaseURI);
        setContractURI(_initContractURI);
        _name = _nameERC721;
        _symbol = _symbolERC721;
        _nextTokenId.increment();
        /// @dev Default royalties.
        _receiver = owner();
        _feeNumerator = 1000;
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    /// @dev Internal override.
    /// @return baseURI URI to build the token URI.
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /// @dev Mints a token to an address with a tokenURI.
    /// @param _to Address of the future owner of the token.
    function mintTo(address _to) private {
        uint256 currentTokenId = _nextTokenId.current();
        require(currentTokenId <= maxSupply(), "total supply limit reached");
        addressMintedBalance[_to]++;
        _nextTokenId.increment();
        _safeMint(_to, currentTokenId);
    }

    /// @dev Bulk mints to an address.
    /// @param _optionId ID of the minting option.
    /// @param _toAddress Address of the future owner of the token.
    function mintOptionTo(uint256 _optionId, address _toAddress)
        external
        payable
        whenNotPaused
    {
        require(canMint(_optionId), "total supply limit reached");

        if (_msgSender() != owner()) {
            require(_saleActive);
            require(canMintAndOwn(_toAddress));
        }

        if (_optionId == COMMON_OPTION) {
            checkValue(msg.value, NUM_COMMON_OPTION);
            for (uint256 i = 0; i < NUM_COMMON_OPTION; i++) {
                mintTo(_toAddress);
            }
        } else if (_optionId == UNCOMMON_OPTION) {
            checkValue(msg.value, NUM_UNCOMMON_OPTION);
            for (uint256 i = 0; i < NUM_UNCOMMON_OPTION; i++) {
                mintTo(_toAddress);
            }
        } else if (_optionId == RARE_OPTION) {
            checkValue(msg.value, NUM_RARE_OPTION);
            for (uint256 i = 0; i < NUM_RARE_OPTION; i++) {
                mintTo(_toAddress);
            }
        } else if (_optionId == EPIC_OPTION) {
            checkValue(msg.value, NUM_EPIC_OPTION);
            for (uint256 i = 0; i < NUM_EPIC_OPTION; i++) {
                mintTo(_toAddress);
            }
        } else if (_optionId == LEGENDARY_OPTION) {
            checkValue(msg.value, NUM_LEGENDARY_OPTION);
            for (uint256 i = 0; i < NUM_LEGENDARY_OPTION; i++) {
                mintTo(_toAddress);
            }
        }
    }

    /// Returns current sale state.
    function saleState() external view returns (bool) {
        return _saleActive;
    }

    // Toggles sales state.
    /// @dev Default: _saleActive = false
    function toggleSaleState() external onlyOwner {
        _saleActive = !_saleActive;
    }

    /// Checks the value of a transaction.
    /// @param value message transaction value.
    /// @param option option id for bulk minting.
    function checkValue(uint256 value, uint256 option)
        private
        view
        returns (bool)
    {
        if (_msgSender() != owner()) {
            require(value >= (option * price()), "amount is not correct");
        }
        return true;
    }

    /// @dev Checks if tx exceeds total supply.
    /// @param _optionId id of item(s) to mint.
    /// @return Boolean "true" if requested amount can be minted and "false" if it exceeds max supply.
    function canMint(uint256 _optionId) public view returns (bool) {
        if (_optionId >= NUM_OPTIONS) {
            return false;
        }
        uint256 numItemsAllocated = 0;
        if (_optionId == COMMON_OPTION) {
            numItemsAllocated = NUM_COMMON_OPTION;
        } else if (_optionId == UNCOMMON_OPTION) {
            numItemsAllocated = NUM_UNCOMMON_OPTION;
        } else if (_optionId == RARE_OPTION) {
            numItemsAllocated = NUM_RARE_OPTION;
        } else if (_optionId == EPIC_OPTION) {
            numItemsAllocated = NUM_EPIC_OPTION;
        } else if (_optionId == LEGENDARY_OPTION) {
            numItemsAllocated = NUM_LEGENDARY_OPTION;
        }
        return totalSupply() <= (maxSupply() - numItemsAllocated);
    }

    /// @dev Ensures _toAddress does not exceed allowed mints and total owning limits per address.
    /// @param _toAddress address of the future owner of the token
    /// @return Boolean "true" if minted balance and owning limit not exceeded, "false" if it exceeds allowed limits.
    function canMintAndOwn(address _toAddress) public view returns (bool) {
        uint256 mintedBalance = addressMintedBalance[_toAddress];
        /// @dev Minter is owner - check mint limit for team
        if (_toAddress == owner()) {
            require(
                mintedBalance + 1 <= maxMintPerAddressTeam(),
                "mint limit for team exceeded"
            );
            return true;
        }
        /// @dev Minter is not owner - check allowed amount of mints and NFTs for address
        uint256 addressBalance = balanceOf(_toAddress);
        require(
            mintedBalance + 1 <= maxMintPerAddress(),
            "mint limit for address exceeded"
        );
        require(
            addressBalance + 1 <= maxNFTPerAddress(),
            "allowed amount of NFTs for an address exceeded"
        );
        return true;
    }

    /// @dev Returns an array of token ids for _owner address.
    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    /// @dev Public function to receive the base token URI.
    /// @return baseURI URI to build the token URI.
    function baseTokenURI() public view returns (string memory) {
        return baseURI;
    }

    /// @dev External function to receive the name of this contract.
    /// @return Name of this contract.
    function name() public view override returns (string memory) {
        return _name;
    }

    /// @dev External function to receive the symbol of this contract.
    /// @return Symbol of this contract.
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /// @dev External function to receive the price of an item.
    /// @return Price for an item
    function price() public view returns (uint256) {
        return _price;
    }

    /// @dev Public function to receive the base contract URI.
    /// @return baseContractURI URI to build the contract URI.
    function contractURI() public view returns (string memory) {
        return baseContractURI;
    }

    /// @dev Public function to receive the amount of NFTs allowed per address.
    /// @return Amount of allowed NFTs per address.
    function maxNFTPerAddress() public view returns (uint256) {
        return _maxNFTPerAddress;
    }

    /// @dev Public function to receive the amount of NFT mints allowed for the team.
    /// @return Amount of allowed NFT mints for the team.
    function maxMintPerAddressTeam() public view returns (uint256) {
        return MAX_MINT_TEAM;
    }

    /// @dev Public function to receive the amount of NFT mints allowed per address.
    /// @return Amount of allowed NFT mints per address.
    function maxMintPerAddress() public view returns (uint256) {
        return _maxMintPerAddress;
    }

    /// @dev Sets the allowed amount of NFTs per address.
    /// @param _newMaxNFTPerAddress New amount allowed to own per address.
    function setMaxNFTPerAddress(uint256 _newMaxNFTPerAddress)
        external
        onlyOwner
    {
        _maxNFTPerAddress = _newMaxNFTPerAddress;
    }

    /// @dev Sets the allowed amount of minted NFTs per address.
    /// @param _newMaxMintPerAddress New amount allowed mints per address.
    function setMaxMintPerAddress(uint256 _newMaxMintPerAddress)
        external
        onlyOwner
    {
        _maxMintPerAddress = _newMaxMintPerAddress;
    }

    /// Sets a new base extension for the metadata.
    /// @dev Defaults to "", but can be set to values like .json.
    /// @param _newBaseExtension The new base extension to set.
    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    /// @dev Sets a new base URI for the NFTs.
    /// @param _newBaseURI The new URI to set as a base.
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    /// Helper for the owner of the contract to set a new contract URI.
    /// @dev Caller must be owner.
    /// @param _newContractURI URI of the new contract.
    function setContractURI(string memory _newContractURI) public onlyOwner {
        baseContractURI = _newContractURI;
    }

    /// @dev External function to set a new proxy registry address.
    /// @param _newProxyRegistryAddress New address of the proxy.
    function setProxyRegistryAddress(address _newProxyRegistryAddress)
        public
        onlyOwner
    {
        _proxyRegistryAddress = _newProxyRegistryAddress;
    }

    /// Sets the default royalty address and fee.
    /// @dev Defaults to "1000" = 10% of transaction value.
    /// @param receiver Wallet address of the new receiver.
    /// @param feeNumerator New fee numerator to set.
    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        public
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /// Sets a new base price for the collection.
    /// @dev Defaults to "1000" = 10% of transaction value.
    /// @param _newPrice New price in MATIC.
    function setPrice(uint256 _newPrice) external onlyOwner {
        _price = _newPrice;
    }

    /// @dev Clears the royalty information for the token..
    /// @param tokenId The NFT id to burn.
    function _burn(uint256 tokenId)
        internal
        virtual
        override(ERC721, ERC721Royalty, ERC721URIStorage)
        onlyOwner
    {
        super._burn(tokenId);
    }

    /// @dev Returns the max amount of NFTs that can exist.
    /// @return Amount of NFTs that can exist.
    function maxSupply() public view returns (uint256) {
        return MAX_SUPPLY;
    }

    /// @dev Pause the contract.
    function pause() public onlyOwner {
        _pause();
    }

    /// @dev Unpause the contract.
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @dev 1 is always subtracted from the Counter since it tracks the next available tokenId.
    /// @return Amount of tokens minted so far.
    function totalSupply() public view override returns (uint256) {
        return _nextTokenId.current() - 1;
    }

    /// @dev Public function to receive the token URI for the NFTs.
    /// @return URI of the NFT token.
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    /// Intercepts all transfers to check for max allowed balance of receiver.
    /// https://docs.openzeppelin.com/contracts/3.x/extending-contracts#using-hooks
    /// @dev Hook into token transfers to ensure receiver "to" does not exceed max NFT address limit.
    /// @param from Wallet address to send the NFT from.
    /// @param to Wallet address to send the NFT to.
    /// @param tokenId NFT id to transfer.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
        if (to != owner()) {
            require(
                balanceOf(to) + 1 <= maxNFTPerAddress(),
                "max NFT per address limit exceeded by receiver"
            );
        }
    }

    /// @dev This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
    function _msgSender() internal view override returns (address sender) {
        return ContextMixin.msgSender();
    }

    /// @dev Check interface support.
    /// @param interfaceId The interface id to check support for.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721Royalty)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @dev Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
    function isApprovedForAll(address owner, address operator)
        public
        view
        override(ERC721)
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        if (address(_proxyRegistryAddress) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /// @dev Withdraw all funds from the contract.
    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}
