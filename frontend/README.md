Frontend for NFT Marketplace (Fractional Royalties)

Quick start

1) Start a local Hardhat node and deploy contracts (if not deployed):

```bash
npx hardhat node
# in another terminal
npm run deploy
```

2) Serve the `frontend` folder (MetaMask disallows file:// usage). Use any static server; e.g.: 

```bash
npx http-server frontend -p 8000
# or
npx serve frontend -p 8000
```

3) Open `http://localhost:8000` in your browser, connect MetaMask, paste deployed contract addresses into the inputs.

Notes
- Use the deployed owner account to call `mintWithRoyalties` (the owner must match the minting caller).
- For `Royalty receivers` enter JSON array of arrays, e.g.:
  ```json
  [["0x90F79bf6EB2c4f870365E785982E1f101E93b906",5000],["0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65",5000]]
  ```
- This frontend is minimal and intended for local testing; adapt ABIs and UI as needed.
