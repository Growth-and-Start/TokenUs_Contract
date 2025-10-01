import { parseAbi, type Address } from 'viem';
import { makeClients, makeClientsBrowser } from './viemClients';

const erc721 = parseAbi([
  'function isApprovedForAll(address owner,address operator) view returns (bool)',
  'function getApproved(uint256 tokenId) view returns (address)',
  'function setApprovalForAll(address operator,bool approved)',
]);

export async function ensureApprovalAll(cfg:{rpcUrl:string,chain:any,account:`0x${string}`, nft:Address, operator:Address}) {
  const { publicClient, walletClient } = makeClientsBrowser(cfg);
  const ok = await publicClient.readContract({ 
    address: cfg.nft, abi: erc721, functionName: 'isApprovedForAll', args: [cfg.account, cfg.operator] 
  }) as boolean;
  if (!ok) {
    const { request } = await publicClient.simulateContract({ 
      address: cfg.nft, abi: erc721, functionName: 'setApprovalForAll', args: [cfg.operator, true], account: cfg.account 
    });
    return walletClient.writeContract(request);
  }
  return null;
}
