// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./PaymentSplitter.sol";

// We create a dedicated RoyaltySplitter contract to hold and divide funds securely
contract RoyaltySplitter is PaymentSplitter {
    constructor(address[] memory payees, uint256[] memory shares) 
        PaymentSplitter(payees, shares) 
    {}
}

contract FractionalRoyaltyNFT is ERC721, ERC2981, Ownable {
    uint256 private _nextTokenId;
    
    // Maps token IDs to their specific fractional royalty splitter contracts
    mapping(uint256 => address) public tokenSplitters;

    constructor(address initialOwner) 
        ERC721("FractionalArt", "FART") 
        Ownable(initialOwner) 
    {}

    /**
     * @notice Mints an NFT and assigns a custom multi-receiver royalty pool to it.
     * @param to The recipient of the minted NFT.
     * @param payees Array of stakeholders who will receive royalties.
     * @param shares Array of proportional weights for each payee.
     * @param feeNumerator The total royalty percentage (e.g., 1000 = 10%).
     */
    function mintWithFractionalRoyalty(
        address to,
        address[] memory payees,
        uint256[] memory shares,
        uint96 feeNumerator
    ) public onlyOwner returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);

        // Deploy a new, isolated PaymentSplitter contract for this specific NFT
        RoyaltySplitter splitter = new RoyaltySplitter(payees, shares);
        tokenSplitters[tokenId] = address(splitter);

        // Set the EIP-2981 royalty receiver to be our newly deployed Splitter contract
        _setTokenRoyalty(tokenId, address(splitter), feeNumerator);

        return tokenId;
    }

    // Necessary overrides for Solidity interface resolution
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}