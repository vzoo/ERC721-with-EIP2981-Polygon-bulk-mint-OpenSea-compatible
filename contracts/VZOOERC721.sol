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

/// @title VZOO NFT contract
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

    /// Enforce the existence of 10.000 VZOO Gorilla NFTs
    uint256 public MAX_SUPPLY = 10000;

    string private _name;
    string private _symbol;

    /// @dev Can be changed after deployment
    string private baseURI;
    string private baseContractURI;
    uint256 private _maxMintTeam = 5000;
    uint256 private _maxMintPerAddress = 36;
    uint256 private _maxNFTPerAddress = 36;
    uint256 private _price = 0.1 ether;
    address public _proxyRegistryAddress;
    string private _baseExtension = "";
    bool private _saleActive = false;
    /// @dev Required by EIP-2981: NFT Royalty Standard
    address private _receiver;
    uint96 private _feeNumerator;
    /// @dev Security considerations can be changed after deployment
    bool private _secAllowMsgSenderOverride = true;
    bool private _secAllowIsApprovedForAll = true;

    /// Five options for bulk minting
    uint256 private NUM_OPTIONS = 5;
    uint256 private numItemsAllocated;

    uint256 private COMMON_OPTION = 0;
    uint256 private UNCOMMON_OPTION = 1;
    uint256 private RARE_OPTION = 2;
    uint256 private EPIC_OPTION = 3;
    uint256 private LEGENDARY_OPTION = 4;

    uint256 private NUM_COMMON_OPTION = 1;
    uint256 private NUM_UNCOMMON_OPTION = 3;
    uint256 private NUM_RARE_OPTION = 9;
    uint256 private NUM_EPIC_OPTION = 18;
    uint256 private NUM_LEGENDARY_OPTION = 36;

    /// @dev Keeps track of wallet addresses that took part in minting our NFTs
    mapping(address => uint256) public addressMintedBalance;

    /// Track nextTokenId instead of currentTokenId to save on gas costs
    /// @dev Uses OpenZeppelin Counter to track the next available ID
    Counters.Counter private _nextTokenId;

    constructor(
        string memory _nameERC721,
        string memory _symbolERC721,
        address _initProxyRegistryAddress,
        string memory _initBaseURI,
        string memory _initContractURI
    ) ERC721(_nameERC721, _symbolERC721) {
        _initializeEIP712(_nameERC721);
        setProxyRegistryAddress(_initProxyRegistryAddress);
        setBaseTokenURI(_initBaseURI);
        setContractURI(_initContractURI);
        _name = _nameERC721;
        _symbol = _symbolERC721;
        _nextTokenId.increment();
        /// @dev Set default royalties for EIP-2981
        _receiver = owner();
        _feeNumerator = 1000;
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    /// Mints next token id to an address
    /// @param _to address of the future token owner
    function mintTo(address _to) internal {
        uint256 currentTokenId = _nextTokenId.current();
        require(currentTokenId <= maxSupply(), "total supply limit reached");
        addressMintedBalance[_to]++;
        _nextTokenId.increment();
        _safeMint(_to, currentTokenId);
    }

    /// Bulk mints NFTs to an address
    /// @param _optionId bulk minting option id
    /// @param _toAddress address of the future token owner
    function mintOptionTo(uint256 _optionId, address _toAddress)
        external
        payable
        whenNotPaused
    {
        require(canMint(_optionId), "total supply limit reached");
        require(canMintAndOwn(_toAddress, numItemsAllocated));

        if (_msgSender() != owner()) {
            require(_saleActive);
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

    /// Checks the value of a transaction
    /// @param value of the transaction message
    /// @param numOption number of NFTs requested for bulk minting
    function checkValue(uint256 value, uint256 numOption)
        internal
        view
        returns (bool)
    {
        if (_msgSender() != owner()) {
            require(value >= (numOption * price()), "transfer amount is not correct");
        }
        return true;
    }

    /// Checks if tx exceeds total supply
    /// @param _optionId bulk mint option id
    /// @return Boolean true if requested bulk amount can be minted, false if it exceeds max supply
    function canMint(uint256 _optionId) public returns (bool) {
        if (_optionId >= NUM_OPTIONS) {
            return false;
        }
        numItemsAllocated = 0;
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

    /// Ensures _toAddress does not exceed allowed mints and total owning limit per address
    /// @param _toAddress address of the future owner of the token
    /// @param requestedNumItemsAllocated number of requested NFTs for bulk minting
    /// @return Boolean true if minting and owning limits not exceeded, otherwise return false
    function canMintAndOwn(
        address _toAddress,
        uint256 requestedNumItemsAllocated
    ) public view returns (bool) {
        uint256 mintedBalance = addressMintedBalance[_toAddress];
        if (_toAddress == owner()) {
            require(
                mintedBalance + requestedNumItemsAllocated <= maxMintTeam(),
                "mint limit for team exceeded"
            );
            return true;
        }
        uint256 addressBalance = balanceOf(_toAddress);
        require(
            mintedBalance + requestedNumItemsAllocated <= maxMintPerAddress(),
            "mint limit for address exceeded"
        );
        require(
            addressBalance + requestedNumItemsAllocated <= maxNFTPerAddress(),
            "allowed amount of NFTs for an address exceeded"
        );
        return true;
    }

    /// Returns an array of token ids for _owner address
    /// @return tokenIds array of token ids for an address
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

    /// External function to receive the name of the NFT collection
    /// @return Name of the NFT collection
    function name() public view override returns (string memory) {
        return _name;
    }

    /// External function to receive the symbol of the NFT collection
    /// @return Symbol of the NFT collection
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /// Returns the max amount of NFTs that can exist
    /// @return Amount that can exist
    function maxSupply() public view returns (uint256) {
        return MAX_SUPPLY;
    }

    /// External function to receive the price for minting one NFT
    /// @return Price for one NFT
    function price() public view returns (uint256) {
        return _price;
    }

    /// Sets a new base price for the collection
    /// @param _newPrice value of the new price
    function setPrice(uint256 _newPrice) external onlyOwner {
        _price = _newPrice;
    }

    /// Public function to receive the current sale state
    /// @return Boolean current state of the sale
    function saleState() external view returns (bool) {
        return _saleActive;
    }

    // Owner toggle for sale state
    function toggleSaleState() external onlyOwner {
        _saleActive = !_saleActive;
    }

    /// Public function to receive the base token URI
    /// @return baseURI to build the token URI
    function baseTokenURI() public view returns (string memory) {
        return baseURI;
    }

    /// Sets a new base URI for the NFTs
    /// @param _newBaseURI the new URI to use as a base
    function setBaseTokenURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    /// Public function to receive the base contract URI
    /// @return URI to build the contract URI
    function contractURI() public view returns (string memory) {
        return baseContractURI;
    }

    /// Helper for the owner of the contract to set a new contract URI
    /// @param _newContractURI new URI for the contract
    function setContractURI(string memory _newContractURI) public onlyOwner {
        baseContractURI = _newContractURI;
    }

    /// Public function to receive the amount of NFTs allowed per address
    /// @return Amount of allowed NFTs per address
    function maxNFTPerAddress() public view returns (uint256) {
        return _maxNFTPerAddress;
    }

    /// Sets the allowed amount of NFTs per address
    /// @param _newMaxNFTPerAddress new amount allowed to own per address
    function setMaxNFTPerAddress(uint256 _newMaxNFTPerAddress)
        external
        onlyOwner
    {
        _maxNFTPerAddress = _newMaxNFTPerAddress;
    }

    /// Public function to receive the amount of NFT mints allowed for the team
    /// @return Amount of allowed NFT mints for the team
    function maxMintTeam() public view returns (uint256) {
        return _maxMintTeam;
    }

    /// Sets the allowed amount of minted NFTs for the team
    /// @param _newMaxMintTeam new amount allowed to mint
    function setMaxMintTeam(uint256 _newMaxMintTeam) external onlyOwner {
        _maxMintTeam = _newMaxMintTeam;
    }

    /// Public function to receive the amount of NFT mints allowed per address
    /// @return Amount of allowed NFT mints per address
    function maxMintPerAddress() public view returns (uint256) {
        return _maxMintPerAddress;
    }

    /// Sets the allowed amount of minted NFTs per address
    /// @param _newMaxMintPerAddress new amount allowed to mint
    function setMaxMintPerAddress(uint256 _newMaxMintPerAddress)
        external
        onlyOwner
    {
        _maxMintPerAddress = _newMaxMintPerAddress;
    }

    /// Receives the currently set base extension for metadata
    function baseExtension() public view returns (string memory) {
        return _baseExtension;
    }

    /// Sets a new base extension for the metadata
    /// @dev Defaults to "", but can be set to values like ".json"
    /// @param _newBaseExtension the new base extension to use
    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        _baseExtension = _newBaseExtension;
    }

    /// External function to set a new proxy registry address
    /// @param _newProxyRegistryAddress new address of the proxy
    function setProxyRegistryAddress(address _newProxyRegistryAddress)
        public
        onlyOwner
    {
        _proxyRegistryAddress = _newProxyRegistryAddress;
    }

    /// Sets the default royalty address and fee
    /// @dev feeNumerator defaults to 1000 = 10% of transaction value
    /// @param receiver wallet address of new receiver
    /// @param feeNumerator new fee numerator
    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        public
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /// Allow or deny override of _msgSender
    /// @param isAllowed true to allow override, false to deny it
    function setSecAllowMsgSenderOverride(bool isAllowed) external onlyOwner {
        _secAllowMsgSenderOverride = isAllowed;
    }

    /// Allow or deny override of _msgSender
    /// @param isAllowed true to allow override, false to deny it
    function setSecAllowIsApprovedForAll(bool isAllowed) external onlyOwner {
        _secAllowIsApprovedForAll = isAllowed;
    }

    /// Clears the royalty information for a token
    /// @dev Required override to comply with EIP-2981
    /// @param tokenId the NFT id to burn royalty information for
    function _burn(uint256 tokenId)
        internal
        virtual
        override(ERC721, ERC721Royalty, ERC721URIStorage)
        onlyOwner
    {
        super._burn(tokenId);
    }

    /// Pauses the contract
    function pause() public onlyOwner {
        _pause();
    }

    /// Unpauses the contract
    function unpause() public onlyOwner {
        _unpause();
    }

    /// Amount of NFTs already minted
    /// @dev 1 is always subtracted from the Counter since it tracks the next available tokenId
    /// @return Amount of tokens minted so far
    function totalSupply() public view override returns (uint256) {
        return _nextTokenId.current() - 1;
    }

    /// Public function to receive the token URI for an NFT
    /// @return URI of the token
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

        string memory currentBaseURI = baseTokenURI();
        string memory currentBaseExtension = baseExtension();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        currentBaseExtension
                    )
                )
                : "";
    }

    /// Intercepts all transfers to ensure receiver does not exceed max allowed balance
    /// @param from wallet address to send the NFT from
    /// @param to wallet address to send the NFT to
    /// @param tokenId NFT id to transfer
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

    /// If allowed, this is used instead of msg.sender as transactions won't be sent by the original token owner, but by the NFT marketplace
    /// @return sender of the message
    function _msgSender() internal view override returns (address sender) {
        if (_secAllowMsgSenderOverride) {
            return ContextMixin.msgSender();
        }
        return super._msgSender();
    }

    /// If allowed, override isApprovedForAll to whitelist user's marketplace proxy accounts to enable gas-less listings
    function isApprovedForAll(address owner, address operator)
        public
        view
        override(ERC721)
        returns (bool)
    {
        if (
            address(_proxyRegistryAddress) == operator &&
            _secAllowIsApprovedForAll
        ) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /// Check interface support.
    /// @param interfaceId the interface id to check support for
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721Royalty)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// Withdraw all funds from the contract
    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}
