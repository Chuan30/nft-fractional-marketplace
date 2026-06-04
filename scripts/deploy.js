import hre from "hardhat";

async function main() {
  await hre.run("compile");

  const FractionalRoyaltyNFT = await hre.ethers.getContractFactory("FractionalRoyaltyNFT");
  const fractionalRoyaltyNFT = await FractionalRoyaltyNFT.deploy();
  await fractionalRoyaltyNFT.waitForDeployment();
  console.log("FractionalRoyaltyNFT deployed to:", fractionalRoyaltyNFT.target);

  const NFTMarketplace = await hre.ethers.getContractFactory("NFTMarketplace");
  const nftMarketplace = await NFTMarketplace.deploy();
  await nftMarketplace.waitForDeployment();
  console.log("NFTMarketplace deployed to:", nftMarketplace.target);

  console.log("Deployment complete.");
  console.log("Use this command to run the script:");
  console.log("  npx hardhat run scripts/deploy.js --network <network>");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});