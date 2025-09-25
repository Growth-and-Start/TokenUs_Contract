import type { Address } from 'viem';
export type ChainConfig = any;
export type Setup = { rpcUrl: string; chain: ChainConfig; account?: `0x${string}`; };
export type DeployedAddresses = { NFT: Address; Market: Address; SplitFactory?: Address; };
export type Listing = { seller: Address; price: bigint; isPrimary: boolean; };
