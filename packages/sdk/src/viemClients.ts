import { createPublicClient, createWalletClient, http, custom } from 'viem';
import type { Setup } from './types';

declare global {
  interface Window {
    ethereum?: any;
  }
}

export function makeClients({ rpcUrl, chain, account }: Setup) {
  const transport = http(rpcUrl);
  const publicClient = createPublicClient({ chain, transport });
  const walletClient = createWalletClient({ chain, transport, account });
  return { publicClient, walletClient };
}


export function makeClientsBrowser({chain}:{chain:any}) {
  const transport = custom(window.ethereum); 
  const publicClient = createPublicClient({ chain, transport });
  const walletClient = createWalletClient({ chain, transport });
  return { publicClient, walletClient };
}