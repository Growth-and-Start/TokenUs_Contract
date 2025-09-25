import { parseAbi, type Address } from 'viem';
import { makeClients, makeClientsBrowser } from './clients';
import type { Listing } from './types';

const marketAbi = parseAbi([
  'function list(address nft,uint256 id,uint256 price,bool isPrimary)',
  'function cancel(address nft,uint256 id)',
  'function buy(address nft,uint256 id) payable',

  'function listings(address nft,uint256 id) view returns (address seller,uint256 price,bool isPrimary)'
]);

// 마켓플레이스에 NFT 판매 등록 
export async function list(cfg:{rpcUrl:string,chain:any,account:`0x${string}`, market:Address, nft:Address, tokenId:bigint, priceWei:bigint, isPrimary:boolean}) {
  const { publicClient, walletClient } = makeClientsBrowser(cfg);
  const { request } = await publicClient.simulateContract({
    address: cfg.market, abi: marketAbi, functionName: 'list',
    args: [cfg.nft, cfg.tokenId, cfg.priceWei, cfg.isPrimary], account: cfg.account
  });
  return walletClient.writeContract(request);
}

// NFT 구매 by 네이티브 코인
export async function buyNative(cfg:{rpcUrl:string,chain:any,account:`0x${string}`, market:Address, nft:Address, tokenId:bigint, valueWei:bigint}) {
  const { publicClient, walletClient } = makeClientsBrowser(cfg);
  const { request } = await publicClient.simulateContract({
    address: cfg.market, abi: marketAbi, functionName: 'buy',
    args: [cfg.nft, cfg.tokenId], value: cfg.valueWei, account: cfg.account
  });
  return walletClient.writeContract(request);
}

// 마켓플레이스에 판매 등록된 NFT 목록 조회
export async function getListing(cfg:{rpcUrl:string,chain:any, market:Address, nft:Address, tokenId:bigint}) {
  const { publicClient } = makeClientsBrowser(cfg);
  const [seller, price, isPrimary] = await publicClient.readContract({
    address: cfg.market, abi: marketAbi, functionName: 'listings', args: [cfg.nft, cfg.tokenId]
  }) as [Address, bigint, boolean];
  return { seller, price, isPrimary } satisfies Listing;
}
