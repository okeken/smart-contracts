//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract SolidNft is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private supply;

    // Our rootHash
    bytes32 public root =
        0xcfaeb198e7509aca7e41d761ebd2976c3f1c9ebef5351407d6a2978c5abea608;

    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;

    uint256 public cost = 0.01 ether;
    uint256 public maxSupply = 10000;
    uint256 public maxMintAmountPerTx = 5;
    uint256 public mintAmtAllowedPresale = 3;

    bool public paused = true;
    bool public revealed = false;
    bool public preSale = true;

    mapping(address => bool) public whiteListClaimed;
    mapping(address => uint256) public amountMintedPreSale;

    constructor() ERC721("NAME", "SYMBOL") {
        setHiddenMetadataUri("ipfs://__CID__/hidden.json");
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
            "Invalid mint amount!"
        );
        require(
            supply.current() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        _;
    }

    function claimCheck() public view {
        require(!whiteListClaimed[msg.sender], "whitelist claimed");
    }

    function totalSupply() public view returns (uint256) {
        return supply.current();
    }

    function checkValidity(bytes32[] calldata _merkleProof) public view {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, root, leaf),
            "Incorrect proof"
        );
    }

    function mint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        public
        payable
        mintCompliance(_mintAmount)
    {
        require(!paused, "The contract is paused!");

        if (preSale) {
            claimCheck();
            checkValidity(_merkleProof);
            whiteListClaimed[msg.sender] = true;
            require(
                amountMintedPreSale[msg.sender] <= mintAmtAllowedPresale,
                "exceed allowed mints"
            );
        }

        require(msg.value >= cost * _mintAmount, "Insufficient funds!");
        _mintLoop(msg.sender, _mintAmount);
        amountMintedPreSale[msg.sender] += 1;
    }

    function mintForAddress(uint256 _mintAmount, address _receiver)
        public
        mintCompliance(_mintAmount)
        onlyOwner
    {
        _mintLoop(_receiver, _mintAmount);
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply
        ) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriSuffix
                    )
                )
                : "";
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function endPreSale(uint256 _cost) public onlyOwner {
        cost = _cost;
        preSale = false;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx)
        public
        onlyOwner
    {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        public
        onlyOwner
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdraw() public onlyOwner {
        (bool hs, ) = payable(0x943590A42C27D08e3744202c4Ae5eD55c2dE240D).call{
            value: (address(this).balance * 5) / 100
        }("");
        require(hs);
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function _mintLoop(address _receiver, uint256 _mintAmount) internal {
        for (uint256 i = 0; i < _mintAmount; i++) {
            supply.increment();
            _safeMint(_receiver, supply.current());
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}
