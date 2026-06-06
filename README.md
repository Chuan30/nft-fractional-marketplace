# NFT Fractional Marketplace

A blockchain project for the Blockchain course (Semester 20252).

---

## Project Idea

This project implements an **NFT Marketplace** with a **Fractional Royalty** system.

Normally, when you sell an NFT, the creator gets a royalty percentage on each resale. In this project, royalties can be **split among multiple receivers** in defined proportions. For example: artist 70%, platform 20%, sponsor 10%.

### Smart Contracts

The project consists of 2 main contracts:

#### 1. FractionalRoyaltyNFT.sol
- An ERC-721 NFT (from OpenZeppelin) with royalty support
- `mintWithRoyalties()` — mint an NFT while specifying multiple royalty receivers and their shares
- Supports EIP-2981 (Royalty Standard)
- Validates that total shares must equal 10000 (100%)

#### 2. NFTMarketplace.sol
- A marketplace that connects with FractionalRoyaltyNFT
- `listNFT()` — list an NFT for sale
- `buyNFT()` — buy an NFT; automatically deducts royalties and distributes them to receivers
- `withdrawPayments()` — withdraw accumulated ETH from sales/royalties

### How it works

```
1. Owner (contract deployer) mints an NFT with royalty receivers
2. NFT owner approves (Approve) the marketplace to manage their NFT
3. NFT owner lists the NFT at a desired price
4. Buyer sends ETH → the system:
   - Deducts royalty fee → pays each receiver proportionally
   - Remaining amount → goes to the seller
   - Transfers NFT to buyer
5. Seller and royalty receivers can withdraw their funds via withdrawPayments()
```

---

## How to Run

### Prerequisites

- [Node.js](https://nodejs.org/) (v18+)
- [MetaMask](https://metamask.io/) browser extension
- Dependencies installed:
  ```bash
  cd "nft-fractional-marketplace"
  npm install
  ```

### Step-by-step

#### 1️⃣ Start a Local Blockchain Node

Open **Terminal 1** and run:

```bash
npx hardhat node
```

This spins up a local Ethereum network and gives you 20 test accounts, each with 10,000 fake ETH.

⚠️ **Keep this terminal running** — the node must stay active.

#### 2️⃣ Deploy Contracts

Open **Terminal 2** (in the same folder) and run:

```bash
npm run deploy
```

You'll see output like:

```
FractionalRoyaltyNFT deployed to: 0x5FbDB2315678afecb367f032d93F642f64180aa3
NFTMarketplace deployed to: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
```

**Copy both addresses** — you'll need them in the UI.

#### 3️⃣ Open the Frontend

Open **Terminal 3** and run:

```bash
npx http-server frontend -p 8000
```

Open your browser and go to: [http://localhost:8000](http://localhost:8000)

---

## How to Use the UI

### Step 1: Connect MetaMask

1. Open MetaMask in your browser
2. Add a custom network:
   - **Network Name**: Localhost 8545
   - **RPC URL**: `http://127.0.0.1:8545`
   - **Chain ID**: `31337`
   - **Currency Symbol**: ETH
3. Import test accounts:
   - In **Terminal 1** (running `npx hardhat node`), you'll see Private Keys:
     ```
     Account #0: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 (10000 ETH)
     Private Key: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
     ```
   - In MetaMask: click your avatar → **Import Account** → paste the Private Key
   - **Import at least 2 accounts** (Account #0 and Account #1) to test buying/selling

### Step 2: Fill in Contract Addresses

| Field | What to enter |
|---|---|
| **FractionalRoyaltyNFT address** | Address from `FractionalRoyaltyNFT deployed to: ...` |
| **NFTMarketplace address** | Address from `NFTMarketplace deployed to: ...` |

Click **Connect Wallet** to link MetaMask.

### Step 3: Mint an NFT

Fill in the **Mint NFT** section:

| Field | Explanation |
|---|---|
| **To** | Leave blank (mints to the connected account) or enter another `0x...` address |
| **Token URI** | Any metadata URL, e.g. `https://example.com/my-nft.json` — **or just type anything** like `hello-world` |
| **Royalty receivers** | JSON array of who gets royalties. Example: `[["0xYourAddress",10000]]` means "one receiver gets 100%" |

Example with multiple receivers:
```json
[
  ["0x90F79bf6EB2c4f870365E785982E1f101E93b906", 5000],
  ["0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65", 5000]
]
```
(First person gets 50%, second gets 50% — shares must add up to 10000)

Click **Mint** and wait for the transaction. Check the **Logs** section at the bottom for status.

### Step 4: List the NFT for Sale

⚠️ **Switch MetaMask to the account that owns the NFT** before continuing.

1. Enter **Token ID** (after the first mint, this is `1`)
2. Enter **Price (ETH)** — e.g. `1`
3. Click **Approve Marketplace** first (gives the marketplace permission to handle your NFT)
4. Click **List NFT**

### Step 5: Buy the NFT

⚠️ **Switch MetaMask to a different account** (one that has ETH).

1. Enter the same Token ID and Price
2. Click **Buy NFT**

### Step 6: Check Balance & Withdraw

- Click **Show My Accrued Balance** — shows how much ETH you've earned (from sales or royalties)
- Click **Withdraw Payments** — transfers that ETH to your wallet

---

## Available Commands

| Command | Description |
|---|---|
| `npm run test` | Run Hardhat test suite |
| `npm run deploy` | Deploy contracts to local network |
| `npx hardhat node` | Start local blockchain node |

---

## Tech Stack

- **Solidity** — Smart contract language
- **Hardhat** — Ethereum development framework
- **OpenZeppelin** — Standard Solidity libraries (ERC-721, ReentrancyGuard)
- **Ethers.js** — Blockchain interaction library for the frontend
- **HTML/CSS/JS** — Simple frontend UI
