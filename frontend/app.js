import { ethers } from 'https://esm.run/ethers@6.16.0';

const logEl = document.getElementById('log');
const connectBtn = document.getElementById('connect');
const accountEl = document.getElementById('account');

let provider, signer;

// Minimal ABIs (only functions we use)
const nftAbi = [
  'function mintWithRoyalties(address to, string memory tokenURI, tuple(address receiver, uint96 share)[] memory receivers) public returns (uint256)',
  'function setApprovalForAll(address operator, bool approved) external',
  'function ownerOf(uint256 tokenId) external view returns (address)'
];
const marketplaceAbi = [
  'function listNFT(address nftAddress, uint256 tokenId, uint256 price) external',
  'function buyNFT(address nftAddress, uint256 tokenId) external payable',
  'function accruedBalances(address) view returns (uint256)',
  'function withdrawPayments() external'
];

function log(...args){
  console.log(...args);
  logEl.textContent += args.map(a=> (typeof a==='object'?JSON.stringify(a,null,2):String(a))).join(' ') + '\n';
}

async function connect(){
  if(!window.ethereum) return alert('Install MetaMask');
  provider = new ethers.BrowserProvider(window.ethereum);
  await provider.send('eth_requestAccounts', []);
  signer = await provider.getSigner();
  const addr = await signer.getAddress();
  accountEl.textContent = 'Connected: ' + addr;
  log('Connected', addr);
}

connectBtn.onclick = connect;

// Mint
document.getElementById('mint').onclick = async ()=>{
  try{
    if(!signer) return alert('Connect wallet first');
    const nftAddress = document.getElementById('nftAddress').value.trim();
    if(!nftAddress) return alert('Set NFT contract address');
    const to = document.getElementById('mintTo').value.trim() || await signer.getAddress();
    const tokenURI = document.getElementById('tokenURI').value.trim();
    const receiversRaw = document.getElementById('receivers').value.trim();
    let receivers = JSON.parse(receiversRaw);
    // ensure each receiver is [address, share]
    // ethers expects array of tuples: we provide array of [addr, share]
    const nft = new ethers.Contract(nftAddress, nftAbi, signer);
    log('Sending mint tx...');
    const tx = await nft.mintWithRoyalties(to, tokenURI, receivers);
    log('Mint tx sent:', tx.hash || tx.transactionHash);
    await tx.wait();
    log('Mint confirmed');
  }catch(err){
    log('Mint error', err.message||err);
  }
}

// Approve
document.getElementById('approve').onclick = async ()=>{
  try{
    if(!signer) return alert('Connect wallet first');
    const nftAddress = document.getElementById('nftAddress').value.trim();
    const marketAddress = document.getElementById('marketAddress').value.trim();
    if(!nftAddress || !marketAddress) return alert('Set both addresses');
    const nft = new ethers.Contract(nftAddress, nftAbi, signer);
    const tx = await nft.setApprovalForAll(marketAddress, true);
    log('Approve tx sent', tx.hash || tx.transactionHash);
    await tx.wait();
    log('Marketplace approved');
  }catch(err){
    log('Approve error', err.message||err);
  }
}

// List
document.getElementById('list').onclick = async ()=>{
  try{
    const nftAddress = document.getElementById('nftAddress').value.trim();
    const marketAddress = document.getElementById('marketAddress').value.trim();
    const tokenId = Number(document.getElementById('tokenId').value.trim());
    const priceEth = document.getElementById('price').value.trim();
    if(!nftAddress||!marketAddress) return alert('Set addresses');
    if(!tokenId) return alert('tokenId invalid');
    const price = ethers.parseEther(priceEth);
    const market = new ethers.Contract(marketAddress, marketplaceAbi, signer);
    const tx = await market.listNFT(nftAddress, tokenId, price);
    log('List tx sent', tx.hash || tx.transactionHash);
    await tx.wait();
    log('Listed');
  }catch(err){
    log('List error', err.message||err);
  }
}

// Buy
document.getElementById('buy').onclick = async ()=>{
  try{
    const nftAddress = document.getElementById('nftAddress').value.trim();
    const marketAddress = document.getElementById('marketAddress').value.trim();
    const tokenId = Number(document.getElementById('tokenId').value.trim());
    const priceEth = document.getElementById('price').value.trim();
    if(!nftAddress||!marketAddress) return alert('Set addresses');
    if(!tokenId) return alert('tokenId invalid');
    const price = ethers.parseEther(priceEth);
    const market = new ethers.Contract(marketAddress, marketplaceAbi, signer);
    const tx = await market.buyNFT(nftAddress, tokenId, { value: price });
    log('Buy tx sent', tx.hash || tx.transactionHash);
    await tx.wait();
    log('Bought');
  }catch(err){
    log('Buy error', err.message||err);
  }
}

// Show balance
document.getElementById('balances').onclick = async ()=>{
  try{
    const marketAddress = document.getElementById('marketAddress').value.trim();
    if(!marketAddress) return alert('Set market address');
    const market = new ethers.Contract(marketAddress, marketplaceAbi, provider);
    const myAddr = await signer.getAddress();
    const bal = await market.accruedBalances(myAddr);
    log('Accrued balance (wei):', bal.toString());
    document.getElementById('balance').textContent = ethers.formatEther(bal) + ' ETH';
  }catch(err){
    log('Balance error', err.message||err);
  }
}

// Withdraw
document.getElementById('withdraw').onclick = async ()=>{
  try{
    const marketAddress = document.getElementById('marketAddress').value.trim();
    if(!marketAddress) return alert('Set market address');
    const market = new ethers.Contract(marketAddress, marketplaceAbi, signer);
    const tx = await market.withdrawPayments();
    log('Withdraw tx sent', tx.hash || tx.transactionHash);
    await tx.wait();
    log('Withdrawn');
  }catch(err){
    log('Withdraw error', err.message||err);
  }
}

log('Frontend loaded.');
