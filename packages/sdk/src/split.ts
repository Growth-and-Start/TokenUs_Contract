import { parseAbi, type Address } from 'viem';
import { makeClients, makeClientsBrowser } from './viemClients';

const factoryAbi = parseAbi(['function create(address,address,uint16) returns (address)']);

export async function create(cfg:{rpcUrl:string,chain:any,account:`0x${string}`, factory:Address, upstream:Address, child:Address, bps:number}) {
  const { publicClient, walletClient } = makeClientsBrowser(cfg);
  const { request } = await publicClient.simulateContract({
    address: cfg.factory, abi: factoryAbi, functionName: 'create',
    args: [cfg.upstream, cfg.child, Number(cfg.bps)], account: cfg.account
  });
  return walletClient.writeContract(request);
}
