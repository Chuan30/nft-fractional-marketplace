import hre from "hardhat";

async function main() {
  console.log('Compile...');
  await hre.run('compile');

  const [owner, seller, buyer, receiver1, receiver2] = await hre.ethers.getSigners();

  console.log('Deploy FractionalRoyaltyNFT...');
  const FractionalRoyaltyNFT = await hre.ethers.getContractFactory('FractionalRoyaltyNFT');
  const fr = await FractionalRoyaltyNFT.deploy();
  await fr.waitForDeployment();
  console.log('FractionalRoyaltyNFT:', fr.target);

  console.log('Deploy NFTMarketplace...');
  const NFTMarketplace = await hre.ethers.getContractFactory('NFTMarketplace');
  const mp = await NFTMarketplace.deploy();
  await mp.waitForDeployment();
  console.log('NFTMarketplace:', mp.target);

  // Mint to seller with 2 receivers 50/50
  const tokenURI = 'https://example.com/metadata/1';
  const receivers = [
    [receiver1.address, 5000],
    [receiver2.address, 5000]
  ];

  console.log('Minting token to seller:', seller.address);
  const mintTx = await fr.mintWithRoyalties(seller.address, tokenURI, receivers);
  await mintTx.wait();
  console.log('Mint tx done');

  const tokenId = 1;
  // Approve marketplace
  console.log('Seller approving marketplace...');
  await fr.connect(seller).setApprovalForAll(mp.target, true);
  console.log('Approved');

  // List NFT
  const price = hre.ethers.parseEther('1');
  console.log('Listing token for price (wei):', price.toString());
  await mp.connect(seller).listNFT(fr.target, tokenId, price);
  console.log('Listed');

  // Buyer buys
  console.log('Buyer buying...');
  await mp.connect(buyer).buyNFT(fr.target, tokenId, { value: price });
  console.log('Bought');

  // Balances
  const sBal = await mp.accruedBalances(seller.address);
  const r1Bal = await mp.accruedBalances(receiver1.address);
  const r2Bal = await mp.accruedBalances(receiver2.address);
  console.log('seller accrued (wei):', sBal.toString());
  console.log('r1 accrued (wei):', r1Bal.toString());
  console.log('r2 accrued (wei):', r2Bal.toString());

  // Withdraw for receiver1
  console.log('Receiver1 withdraw...');
  await mp.connect(receiver1).withdrawPayments();
  console.log('Receiver1 withdrew');

  // Withdraw for seller
  console.log('Seller withdraw...');
  await mp.connect(seller).withdrawPayments();
  console.log('Seller withdrew');

  console.log('Verification script completed successfully.');
}

main().catch((e)=>{ console.error(e); process.exitCode=1; });
