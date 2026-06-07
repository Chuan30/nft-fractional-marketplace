// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IFractionalNFT {
    struct RoyaltyReceiver {
        address receiver;
        uint96 share;
    }
    function getRoyaltyReceivers(uint256 tokenId) external view returns (RoyaltyReceiver[] memory);
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount);
}

contract NFTMarketplace is ReentrancyGuard {
    struct Listing {
        address seller;
        uint256 price;
        bool isActive;
    }

    mapping(address => mapping(uint256 => Listing)) public listings;
    mapping(address => uint256) public accruedBalances;

    event NFTListed(address indexed seller, address indexed nftAddress, uint256 indexed tokenId, uint256 price);
    event NFTSold(address indexed buyer, address indexed nftAddress, uint256 indexed tokenId, uint256 price);
    event Withdrawn(address indexed user, uint256 amount);

    function listNFT(address nftAddress, uint256 tokenId, uint256 price) external {
        require(price > 0, "Price must be greater than zero");
        IERC721 nft = IERC721(nftAddress);
        require(nft.ownerOf(tokenId) == msg.sender, "Not the owner");
        require(
            nft.isApprovedForAll(msg.sender, address(this)) ||
            nft.getApproved(tokenId) == address(this),
            "Marketplace not approved"
        );

        listings[nftAddress][tokenId] = Listing({
            seller: msg.sender,
            price: price,
            isActive: true
        });

        emit NFTListed(msg.sender, nftAddress, tokenId, price);
    }

    function buyNFT(address nftAddress, uint256 tokenId) external payable nonReentrant {
        Listing storage listing = listings[nftAddress][tokenId];
        require(listing.isActive, "NFT not listed for sale");
        require(msg.value == listing.price, "Incorrect ETH amount sent");

        listing.isActive = false;
        address seller = listing.seller;
        uint256 salePrice = listing.price;

        uint256 totalRoyaltyAmount = 0;

        try IFractionalNFT(nftAddress).royaltyInfo(tokenId, salePrice) returns (address, uint256 royaltyAmount) {
            if (royaltyAmount > 0 && royaltyAmount < salePrice) {
                totalRoyaltyAmount = royaltyAmount;
                IFractionalNFT.RoyaltyReceiver[] memory receivers = IFractionalNFT(nftAddress).getRoyaltyReceivers(tokenId);
                for (uint256 i = 0; i < receivers.length; i++) {
                    uint256 receiverShare = (royaltyAmount * receivers[i].share) / 10000;
                    accruedBalances[receivers[i].receiver] += receiverShare;
                }
            }
        } catch {
            totalRoyaltyAmount = 0;
        }

        uint256 sellerProceeds = salePrice - totalRoyaltyAmount;
        accruedBalances[seller] += sellerProceeds;

        delete listings[nftAddress][tokenId];
        IERC721(nftAddress).safeTransferFrom(seller, msg.sender, tokenId);

        emit NFTSold(msg.sender, nftAddress, tokenId, salePrice);
    }

    function withdrawPayments() external nonReentrant {
        uint256 amount = accruedBalances[msg.sender];
        require(amount > 0, "No funds available for withdrawal");

        accruedBalances[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");

        emit Withdrawn(msg.sender, amount);
    }
}
