import { parseAbi, type Address } from 'viem';
import { makeClients, makeClientsBrowser } from './clients';

const nftAbi = parseAbi([
  'function createOriginalWork(uint256,address, address)',
  'function mintEditionBatch(address,uint256,uint256) returns (uint256[])',
  'function createDerivativeWork(uint256,uint256,address,uint16) returns (address)',
  'function mintDerivativeEditionBatch(address,uint256,uint256,uint256) returns (uint256[])',
  
  'function splitOf(uint256) view returns (address)',
  'function parentOf(uint256) view returns (uint256)',
  'function creatorOf(uint256) view returns (address)',
  'function workOf(uint256) view returns (uint256)',

  
]);

// 원본 작품 생성
export async function createOriginalWork(cfg:{
  rpcUrl:string, chain:any, account:`0x${string}`, nft:Address,
  workId:bigint, creator:Address, split?:Address
}) {
  const { publicClient, walletClient } = makeClients(cfg);
  const { request } = await publicClient.simulateContract({
    address: cfg.nft, abi: nftAbi, functionName: 'createOriginalWork',
    args: [cfg.workId, cfg.creator, (cfg.split ?? '0x0000000000000000000000000000000000000000') as Address],
    account: cfg.account
  });
  return walletClient.writeContract(request);
}

// nft 민팅
export async function mintEditionBatch(cfg:{
  rpcUrl:string, chain:any, account:`0x${string}`, nft:Address, to:Address, workId:bigint, amount:number|bigint
}) {
  const { publicClient, walletClient } = makeClientsBrowser(cfg);
  const amt = typeof cfg.amount==='bigint'?cfg.amount:BigInt(cfg.amount);
  const { request } = await publicClient.simulateContract({
    address: cfg.nft, abi: nftAbi, functionName: 'mintEditionBatch',
    args: [cfg.to, cfg.workId, amt], account: cfg.account
  });
  return walletClient.writeContract(request);
}

// 파생 작품 생성
export async function createDerivativeWork(cfg:{
  rpcUrl:string, chain:any, account:`0x${string}`, nft:Address,
  parentTokenId:bigint, childWorkId:bigint, childCreator:Address, upstreamBps:number
}) {
  const { publicClient, walletClient } = makeClientsBrowser(cfg);
  const { request } = await publicClient.simulateContract({
    address: cfg.nft, abi: nftAbi, functionName: 'createDerivativeWork',
    args: [cfg.parentTokenId, cfg.childWorkId, cfg.childCreator, Number(cfg.upstreamBps)],
    account: cfg.account
  });
  return walletClient.writeContract(request);
}

// 파생 작품 nft 민팅 + 계보 연결
export async function mintDerivativeEditionBatch(cfg:{
  rpcUrl:string, chain:any, account:`0x${string}`, nft:Address,
  to:Address, childWorkId:bigint, parentTokenId:bigint, amount:number|bigint
}) {
  const { publicClient, walletClient } = makeClientsBrowser(cfg);
  const amt = typeof cfg.amount==='bigint'?cfg.amount:BigInt(cfg.amount);
  const { request } = await publicClient.simulateContract({
    address: cfg.nft, abi: nftAbi, functionName: 'mintDerivativeEditionBatch',
    args: [cfg.to, cfg.childWorkId, cfg.parentTokenId, amt], account: cfg.account
  });
  return walletClient.writeContract(request);
}
