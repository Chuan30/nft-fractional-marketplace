// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

contract FractionalRoyaltyNFT is ERC721URIStorage, IERC2981, Ownable {
    
    struct RoyaltyReceiver {
        address receiver;
        uint96 share; // T? l? ph?n tr�m (v� d?: 5000 = 50%)
    }

    mapping(uint256 => RoyaltyReceiver[]) private _tokenRoyalties;
    
    uint256 private constant FEE_DENOMINATOR = 10000;
    
    uint256 private _tokenIds;

    constructor() ERC721("Fractional Royalty NFT", "FRNFT") Ownable(msg.sender) {}

    function mintWithRoyalties(
        address to,
        string memory tokenURI,
        RoyaltyReceiver[] memory receivers
    ) public onlyOwner returns (uint256) {
        uint256 totalShare = 0;
        for (uint256 i = 0; i < receivers.length; i++) {
            require(receivers[i].receiver != address(0), "Invalid receiver");
            totalShare += receivers[i].share;
        }
        require(totalShare == FEE_DENOMINATOR, "Total shares must equal 10000 (100%)");

        _tokenIds++;
        uint256 newTokenId = _tokenIds;

        _safeMint(to, newTokenId);
        _setTokenURI(newTokenId, tokenURI);

        for (uint256 i = 0; i < receivers.length; i++) {
            _tokenRoyalties[newTokenId].push(receivers[i]);
        }

        return newTokenId;
    }

    function getRoyaltyReceivers(uint256 tokenId) external view returns (RoyaltyReceiver[] memory) {
        return _tokenRoyalties[tokenId];
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) 
        external 
        view 
        override 
        returns (address receiver, uint256 royaltyAmount) 
    {
        uint256 totalRoyaltyRate = 1000; // 10%
        royaltyAmount = (salePrice * totalRoyaltyRate) / FEE_DENOMINATOR;
        return (address(this), royaltyAmount);
    }

    function supportsInterface(bytes4 interfaceId) 
        public 
        view 
        override(ERC721URIStorage, IERC165) 
        returns (bool) 
    {
        return super.supportsInterface(interfaceId);
    }
}
