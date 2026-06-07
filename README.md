# Fractional Royalty NFT Marketplace

A blockchain project for minting and trading NFTs with fractional royalty splitting (multiple stakeholders can share royalties).

## Contracts Overview

| File | Purpose |
|------|---------|
| `contracts/Token.sol` | NFT contract (FractionalRoyaltyNFT) + RoyaltySplitter |
| `contracts/PaymentSplitter.sol` | Core logic for splitting ETH payments by shares |
| `contracts/Marketplace.sol` | Marketplace that auto-distributes royalties on sale |

## How to Run (Remix IDE)

1. Go to [Remix IDE](https://remix.ethereum.org/)
2. Open this project folder (or upload the files)
3. Go to the **Solidity Compiler** tab
   - Set compiler version to `0.8.20+`
   - Compile all 3 files: Token.sol, PaymentSplitter.sol, Marketplace.sol
4. Go to the **Deploy & Run Transactions** tab
   - Environment: **Remix VM** (or Sepolia testnet if you want real testing)
   - Deploy in the order below

## Step-by-Step Test Guide

### Step 1: Deploy FractionalRoyaltyNFT
- Select Contract: `FractionalRoyaltyNFT`
- Click Deploy (pass your address as `initialOwner`)
- Copy the deployed contract address

### Step 2: Mint an NFT with Fractional Royalty
- Select your deployed `FractionalRoyaltyNFT`
- Call `mintWithFractionalRoyalty`
  - `to`: address to receive the NFT
  - `payees`: e.g. `["0x...A", "0x...B"]` (royalty receivers)
  - `shares`: e.g. `[60, 40]` (60% to A, 40% to B)
  - `feeNumerator`: e.g. `1000` = 10% royalty (EIP-2981 standard)

### Step 3: Approve the Marketplace
- Call `setApprovalForAll` on the NFT contract
  - `operator`: address of your Marketplace (deploy it first if you haven't)
  - `approved`: `true`

### Step 4: Deploy AtomicNFTMarketplace
- Select Contract: `AtomicNFTMarketplace`
- Click Deploy

### Step 5: List Your NFT for Sale
- Call `listNFT` on the Marketplace
  - `nftAddress`: your NFT contract address
  - `tokenId`: e.g. `0` (first minted token)
  - `price`: e.g. `1000000000000000000` (1 ETH)

### Step 6: Buy the NFT
- Switch to a different account in Remix
- Call `buyNFT` with `value` >= the listing price
  - `nftAddress`: your NFT contract address
  - `tokenId`: `0`
- Funds are distributed automatically:
  - Royalty → RoyaltySplitter contract
  - Remaining → Seller

### Step 7: Claim Royalties
- Find the RoyaltySplitter address via `tokenSplitters(0)` on the NFT contract
- Switch to the RoyaltySplitter contract in Remix
- Call `release` with your address as `account`
- ETH is released based on the share percentages you set

## System Architecture

```
                   ┌───────────────────────┐
                   │  FractionalRoyaltyNFT │
                   │  (ERC721 + ERC2981)   │
                   └──────────┬────────────┘
                              │ Each token has its
                              │ own RoyaltySplitter
                   ┌──────────▼───────────┐
                   │   RoyaltySplitter    │
                   │  (PaymentSplitter)   │
                   │  Splits % by shares  │
                   └──────────────────────┘

When a sale happens:
  Buyer → sends ETH → Marketplace
                         ├─ sends Royalty → RoyaltySplitter
                         ├─ sends rest → Seller
                         └─ transfers NFT → Buyer
```

## Notes

- No external tools needed — everything runs inside Remix IDE
- To deploy on a real network (Sepolia), you'll need MetaMask and some test ETH for gas
- The `.deps/` folder contains OpenZeppelin dependencies auto-fetched by Remix — don't touch it
