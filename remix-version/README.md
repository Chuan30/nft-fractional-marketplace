# NFT Fractional Marketplace — How to Run in Remix

This guide will help you compile, deploy, and test the NFT Fractional Marketplace using [Remix IDE](https://remix.ethereum.org/).

---

## What's in this folder?

| File | What it does |
|---|---|
| `FractionalRoyaltyNFT.sol` | NFT contract that can mint tokens and split royalties to multiple people |
| `NFTMarketplace.sol` | Marketplace where you can list and buy NFTs. Automatically handles royalty payments |
| `README.md` | This file — instructions for you |

---

## Step 1: Open Remix and Upload Files

1. Go to [https://remix.ethereum.org/](https://remix.ethereum.org/)
2. It might ask to open a workspace — click **"Default workspace"** or just close the popup
3. In the left sidebar (File Explorer), you'll see a folder called `contracts/`
4. Right-click `contracts/` → **Upload** → select both `.sol` files from this folder

---

## Step 2: Turn on NPM Auto-Resolution

These contracts use OpenZeppelin libraries (like ERC-721). Remix needs to download them from NPM.

1. Click the **Solidity Compiler** icon in the left sidebar (it looks like a little book with 'S' — 2nd icon from top)
2. Scroll down to the bottom of the compiler panel
3. Click **"Advanced Configurations"** to expand it
4. Turn **ON** the toggle that says **"Auto resolve NPM dependencies"**

---

## Step 3: Compile the Contracts

1. Click on `FractionalRoyaltyNFT.sol` in the file list (left panel)
2. In the compiler panel:
   - Set **Compiler version** to `0.8.24` or `0.8.26` (anything 0.8.24 or newer)
   - Click **"Compile FractionalRoyaltyNFT.sol"**
   - If everything is green ✅, it worked!
3. Now click on `NFTMarketplace.sol` in the file list
4. Click **"Compile NFTMarketplace.sol"**
5. You should see green checkmarks on both files

---

## Step 4: Deploy the Contracts

1. Click the **Deploy & Run Transactions** icon in the left sidebar (it looks like an Ethereum diamond with a play button ▶️ — 3rd icon from top)
2. Set **Environment** to `Remix VM (Cancun)`
   - This creates a fake local Ethereum network inside your browser
   - You get 10 test accounts with 100 ETH each
   - No MetaMask needed
3. You'll see a **CONTRACT** dropdown at the top of the panel
4. From the dropdown, select **FractionalRoyaltyNFT**
5. Click the orange **Deploy** button
6. Wait a few seconds — you'll see a deployed contract appear in the "Deployed Contracts" section at the bottom
7. Click the copy button (📋) next to it to copy the address
8. Now from the **CONTRACT** dropdown, select **NFTMarketplace**
9. Click **Deploy**
10. Copy this address too

---

## Step 5: Mint an NFT

1. Under "Deployed Contracts", expand **FractionalRoyaltyNFT** (click the arrow ▶️ next to it)
2. You'll see a bunch of buttons — these are the functions you can call
3. Find the `mintWithRoyalties` function and fill in:

| Parameter | What to type | Example |
|---|---|---|
| `to` | Your account address | Click the "Account" dropdown at the top of the Deploy panel, copy the first address and paste it here |
| `tokenURI` | Any text — this would be a metadata URL in real life | `"my-first-nft"` |
| `receivers` | Who gets royalties and how much (in percentage) | `[["0x...YourAddress...", 10000]]` |

**How receivers works:**
- Each receiver is written as `["0xAddress", share]`
- Share is in "basis points" where 10000 = 100%
- So `[["0x...", 10000]]` = one person gets 100%
- For multiple people: `[["0xAddr1", 5000], ["0xAddr2", 5000]]` = 50/50 split

**Important:** Shares must add up to exactly 10000, or the contract will reject it.

4. Click the `mintWithRoyalties` button (yes, it looks like a button, not an input field)
5. Wait for the transaction to go through

---

## Step 6: Approve the Marketplace

Before you can sell your NFT, the marketplace needs permission to transfer it.

1. Still in the **FractionalRoyaltyNFT** contract
2. Find the `setApprovalForAll` function
3. Fill in:

| Parameter | What to type |
|---|---|
| `operator` | The address of **NFTMarketplace** you copied earlier |
| `approved` | `true` (select `true` from the dropdown) |

4. Click the button to send the transaction

---

## Step 7: List the NFT for Sale

Now switch to the **NFTMarketplace** contract.

1. Expand **NFTMarketplace** under "Deployed Contracts"
2. Find the `listNFT` function
3. Fill in:

| Parameter | What to type | Example |
|---|---|---|
| `nftAddress` | The address of **FractionalRoyaltyNFT** | `0xd8b934580fcE35a11B58C6D73aDeE468a2833fa8` |
| `tokenId` | The ID of your NFT (first mint = 1) | `1` |
| `price` | Price **in wei** (not ETH!) | See note below |

**About price — the annoying part:**
Solidity doesn't understand "1 ETH" directly. You need to type the number in **wei** (the smallest unit).
- 1 ETH = 1000000000000000000 wei (1 followed by 18 zeros)
- 0.5 ETH = 500000000000000000
- 0.1 ETH = 100000000000000000

**Pro tip:** Keep a tab open with "ethereum unit converter" or just copy-paste the number above.

4. Click the button to list your NFT
5. You should see a green checkmark and an `NFTListed` event in the Remix console (bottom panel)

---

## Step 8: Buy the NFT (Switch Accounts)

1. In the **Deploy & Run** panel, look at the **Account** dropdown (just above the CONTRACT dropdown)
2. You'll see something like:
   ```
   0x5B3... (100 ETH)
   0xAb8... (100 ETH)
   ```
3. Select a **different account** (not the one that owns the NFT)
4. Now we need to tell Remix: "send ETH along with this transaction"
   - Find the **Value** field above the Account dropdown
   - Type `1` and select **Ether** from the dropdown (not Wei!)
   - This means "I want to send 1 ETH with the next transaction"
5. Now in the `buyNFT` function:

| Parameter | What to type |
|---|---|
| `nftAddress` | Same FractionalRoyaltyNFT address |
| `tokenId` | `1` |

6. Click the `buyNFT` button
7. If it works, you'll see an `NFTSold` event in the console

---

## Step 9: Check Balances and Withdraw

### Check how much money you have

1. Find the `accruedBalances` function in **NFTMarketplace** (it's a read function)
2. Type your address next to it and click — it will show your ETH balance in wei

### Withdraw (claim) your money

1. Make sure you're using the **same account** that has a balance
2. Click the `withdrawPayments` button
3. The ETH goes to your wallet

---

## Quick Workflow Summary

```
1. Upload .sol files to Remix
2. Enable "Auto resolve NPM dependencies" in compiler settings
3. Compile both contracts (Solidity 0.8.24+)
4. Deploy FractionalRoyaltyNFT → copy address
5. Deploy NFTMarketplace → copy address

--- Mint ---
6. Call mintWithRoyalties(to, "uri", [["0x...", 10000]])

--- Sell ---
7. Call setApprovalForAll(marketplaceAddr, true)
8. Call listNFT(nftAddr, 1, 1000000000000000000)

--- Buy ---
9. Switch to a different account in the Account dropdown
10. Set Value = 1 Ether
11. Call buyNFT(nftAddr, 1)

--- Withdraw ---
12. Call withdrawPayments()
```

---