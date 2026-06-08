// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract AtomicNFTMarketplace is ReentrancyGuard {
    
    struct Listing {
        address seller;
        address nftAddress;
        uint256 tokenId;
        uint256 price;
        bool isActive;
    }

    // NFT Address => Token ID => Listing details
    mapping(address => mapping(uint256 => Listing)) public listings;

    event NFTListed(address indexed seller, address indexed nftAddress, uint256 indexed tokenId, uint256 price);
    event NFTSold(address indexed buyer, address indexed nftAddress, uint256 indexed tokenId, uint256 price);

    function listNFT(address nftAddress, uint256 tokenId, uint256 price) external {
        require(price > 0, "Price must be greater than zero");
        IERC721 nft = IERC721(nftAddress);
        require(nft.ownerOf(tokenId) == msg.sender, "Not the owner");
        require(nft.isApprovedForAll(msg.sender, address(this)) || nft.getApproved(tokenId) == address(this), "Marketplace not approved");

        listings[nftAddress][tokenId] = Listing({
            seller: msg.sender,
            nftAddress: nftAddress,
            tokenId: tokenId,
            price: price,
            isActive: true
        });

        emit NFTListed(msg.sender, nftAddress, tokenId, price);
    }

    /**
     * @notice Purchases an NFT, calculates and routes royalties atomically.
     * Prevents reentrancy entirely via nonReentrant and Check-Effects-Interactions.
     */
    function buyNFT(address nftAddress, uint256 tokenId) external payable nonReentrant {
        Listing storage listing = listings[nftAddress][tokenId];
        require(listing.isActive, "Listing not active");
        require(listing.seller != msg.sender, "Cant buy own listing")
        require(msg.value >= listing.price, "Insufficient funds sent");

        // Effects
        listing.isActive = false;
        address seller = listing.seller;
        uint256 salePrice = listing.price;

        // 1. Calculate Royalties using EIP-2981 Introspection
        address royaltyReceiver;
        uint256 royaltyAmount;
        
        if (IERC165(nftAddress).supportsInterface(type(IERC2981).interfaceId)) {
            (royaltyReceiver, royaltyAmount) = IERC2981(nftAddress).royaltyInfo(tokenId, salePrice);
        }

        // 2. Interactions (Atomic Distribution of Funds)
        uint256 sellerProceeds = salePrice;

        if (royaltyReceiver != address(0) && royaltyAmount > 0) {
            sellerProceeds -= royaltyAmount;
            
            // Send royalty directly to the Splitter contract
            // We use standard call, but since receiver is a Splitter contract, it just receives the ETH natively
            (bool royaltySuccess, ) = royaltyReceiver.call{value: royaltyAmount}("");
            require(royaltySuccess, "Royalty distribution failed");
        }

        // Send the remaining revenue to the seller
        (bool sellerSuccess, ) = seller.call{value: sellerProceeds}("");
        require(sellerSuccess, "Seller payment failed");

        // 3. Atomic Asset Transfer
        IERC721(nftAddress).safeTransferFrom(seller, msg.sender, tokenId);

        // Refund excess ETH if the buyer overpaid
        if (msg.value > salePrice) {
            (bool refundSuccess, ) = msg.sender.call{value: msg.value - salePrice}("");
            require(refundSuccess, "Refund failed");
        }

        emit NFTSold(msg.sender, nftAddress, tokenId, salePrice);
    }
}
