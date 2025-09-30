import { parseAbi, type Address } from 'viem';
import { makeClientsBrowser } from './clients';

const nftAbi = parseAbi([
  'function createOriginalWork(uint256,address, address)',
  'function mintEditionBatch(address,uint256,uint256) returns (uint256[])',
  'function createDerivativeWork(uint256,uint256,address,uint16) returns (address)',
  'function mintDerivativeEditionBatch(address,uint256,uint256,uint256) returns (uint256[])',

  'function works(uint256) view returns (address, address, bool)',
  'function getTokensOfWork(uint256) view returns(uint256[])',
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

  const { publicClient, walletClient } = makeClientsBrowser(cfg);

      const currentId = await walletClient.getChainId();
  if (currentId !== cfg.chain.id) {
  await walletClient.switchChain({ id: cfg.chain.id }); }

  const { request } = await publicClient.simulateContract({
    address: cfg.nft, abi: nftAbi, functionName: 'createOriginalWork',
    args: [cfg.workId, cfg.creator, (cfg.split ?? '0x0000000000000000000000000000000000000000') as Address],
    account: cfg.account
  });

  return walletClient.writeContract(request);
}

// nft 민팅
export async function mintEditionBatch(cfg:{
  rpcUrl:string, chain:import('viem').Chain, account:`0x${string}`, nft:Address, to:Address, workId:bigint, amount:number|bigint
}) {
  const { publicClient, walletClient } = makeClientsBrowser(cfg);

    const currentId = await walletClient.getChainId();
  if (currentId !== cfg.chain.id) {
  await walletClient.switchChain({ id: cfg.chain.id }); 
}

  const amt = typeof cfg.amount==='bigint'?cfg.amount:BigInt(cfg.amount);
  const { request } = await publicClient.simulateContract({
    address: cfg.nft, abi: nftAbi, functionName: 'mintEditionBatch',
    args: [cfg.to, cfg.workId, amt], account: cfg.account
  });
  return walletClient.writeContract(request);
}

// 원본 작품 생성 + nft 민팅

// 파생 작품 생성
export async function createDerivativeWork(cfg:{
  rpcUrl:string, chain:import('viem').Chain, account:`0x${string}`, nft:Address,
  parentTokenId:bigint, childWorkId:bigint, childCreator:Address, upstreamBps:number
}) {
  const { publicClient, walletClient } = makeClientsBrowser(cfg);

  const currentId = await walletClient.getChainId();
  if (currentId !== cfg.chain.id) {
  await walletClient.switchChain({ id: cfg.chain.id }); 
}

  const { request } = await publicClient.simulateContract({
    address: cfg.nft, abi: nftAbi, functionName: 'createDerivativeWork',
    args: [cfg.parentTokenId, cfg.childWorkId, cfg.childCreator, Number(cfg.upstreamBps)],
    account: cfg.account
  });
  return walletClient.writeContract(request);
}

// 파생 작품 nft 민팅 + 계보 연결
export async function mintDerivativeEditionBatch(cfg:{
  rpcUrl:string, chain:import('viem').Chain, account:`0x${string}`, nft:Address,
  to:Address, childWorkId:bigint, parentTokenId:bigint, amount:number|bigint
}) {
  const { publicClient, walletClient } = makeClientsBrowser(cfg);

  const currentId = await walletClient.getChainId();
  if (currentId !== cfg.chain.id) {
  await walletClient.switchChain({ id: cfg.chain.id }); 
}

  const amt = typeof cfg.amount==='bigint'?cfg.amount:BigInt(cfg.amount);
  const { request } = await publicClient.simulateContract({
    address: cfg.nft, abi: nftAbi, functionName: 'mintDerivativeEditionBatch',
    args: [cfg.to, cfg.childWorkId, cfg.parentTokenId, amt], account: cfg.account
  });
  return walletClient.writeContract(request);
}

// 파생 작품 생성 + nft 민팅


// 특정 작품의 토큰 아이디 배열 가져오기
export async function getTokensOfWork(workId:bigint, chain:import('viem').Chain, nft:Address){
  const {publicClient} = makeClientsBrowser({chain});

  const tokenIds = await publicClient.readContract({
      address: nft,
      abi: nftAbi,
      functionName: 'getTokensOfWork',
      args: [workId], 
    });

  return tokenIds;
}