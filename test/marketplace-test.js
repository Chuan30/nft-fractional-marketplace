import { expect } from "chai";
import hardhat from "hardhat";

const { ethers } = hardhat;

describe("NFT Marketplace", function () {
  let fractionalRoyaltyNFT;
  let nftMarketplace;
  let owner;
  let seller;
  let buyer;
  let receiver1;
  let receiver2;

  beforeEach(async function () {
    [owner, seller, buyer, receiver1, receiver2] = await ethers.getSigners();

    const FractionalRoyaltyNFT = await ethers.getContractFactory("FractionalRoyaltyNFT");
    fractionalRoyaltyNFT = await FractionalRoyaltyNFT.deploy();
    await fractionalRoyaltyNFT.waitForDeployment();

    const NFTMarketplace = await ethers.getContractFactory("NFTMarketplace");
    nftMarketplace = await NFTMarketplace.deploy();
    await nftMarketplace.waitForDeployment();

  });

  it("should mint, list, buy, and withdraw payments correctly", async function () {
    const tokenURI = "https://example.com/metadata/1";
    const royaltyReceivers = [
      [receiver1.address, 5000],
      [receiver2.address, 5000],
    ];

    const mintTx = await fractionalRoyaltyNFT.mintWithRoyalties(
      seller.address,
      tokenURI,
      royaltyReceivers
    );
    await mintTx.wait();

    const tokenId = 1;
    expect(await fractionalRoyaltyNFT.ownerOf(tokenId)).to.equal(seller.address);

    await fractionalRoyaltyNFT.connect(seller).setApprovalForAll(nftMarketplace.target, true);

    const price = ethers.parseEther("1");
    await nftMarketplace.connect(seller).listNFT(fractionalRoyaltyNFT.target, tokenId, price);
    await nftMarketplace.connect(buyer).buyNFT(fractionalRoyaltyNFT.target, tokenId, { value: price });

    expect(await fractionalRoyaltyNFT.ownerOf(tokenId)).to.equal(buyer.address);

    const sellerBalance = await nftMarketplace.accruedBalances(seller.address);
    const receiver1Balance = await nftMarketplace.accruedBalances(receiver1.address);
    const receiver2Balance = await nftMarketplace.accruedBalances(receiver2.address);

    const expectedRoyaltyShare = (price * 5n) / 100n;
    const expectedSellerShare = (price * 90n) / 100n;

    expect(receiver1Balance).to.equal(expectedRoyaltyShare);
    expect(receiver2Balance).to.equal(expectedRoyaltyShare);
    expect(sellerBalance).to.equal(expectedSellerShare);

    await expect(nftMarketplace.connect(receiver1).withdrawPayments())
      .to.emit(nftMarketplace, "Withdrawn")
      .withArgs(receiver1.address, receiver1Balance);

    await expect(nftMarketplace.connect(receiver2).withdrawPayments())
      .to.emit(nftMarketplace, "Withdrawn")
      .withArgs(receiver2.address, receiver2Balance);

    await expect(nftMarketplace.connect(seller).withdrawPayments())
      .to.emit(nftMarketplace, "Withdrawn")
      .withArgs(seller.address, sellerBalance);
  });
});
