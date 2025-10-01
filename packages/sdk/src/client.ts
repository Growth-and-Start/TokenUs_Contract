import type { Chain, Address } from "viem";
import { createPublicClient, http } from "viem";
import * as rawApprovals from "./approvals";
import * as rawNft from "./nft";
import * as rawMarket from "./market";
import * as rawSplit from "./split";

export type ClientOptions = {
  rpcUrl: string;
  chain: Chain;
  account?: `0x${string}`|undefined;
  addresses: { NFT: Address; Market: Address; SplitFactory?: Address };
};

export class Client {
  readonly rpcUrl: string;
  readonly chain: Chain;
  account?: `0x${string}` | undefined;
  readonly addresses: ClientOptions["addresses"];

  constructor(opts: ClientOptions) {
    this.rpcUrl = opts.rpcUrl;
    this.chain = opts.chain;
    this.account = opts.account;
    this.addresses = opts.addresses;
  }

  setAccount(account: `0x${string}`) {
    this.account = account;
  }

  private ensureAccount(): `0x${string}` {
    if (!this.account) {
      throw new Error("Client account is not set. Please connect a wallet first.");
    }
    return this.account;
  }

  // 트랜잭션 채굴 대기
  waitMining = async(hash:Address)=>{
      const publicClient = createPublicClient({
      chain: this.chain,
      transport: http(this.rpcUrl),
    });

    const receipt = await publicClient.waitForTransactionReceipt({hash});
    return receipt;
  }


  // ----- Approvals
  approvals = {
    ensureApprovalAll: async (
      args: { operator?: Address; nft?: Address } & { owner?: `0x${string}` }
    ) => {
      const owner = args.owner ?? this.ensureAccount();
      const nft = args.nft ?? this.addresses.NFT;
      const operator = args.operator ?? this.addresses.Market;
      return rawApprovals.ensureApprovalAll({
        rpcUrl: this.rpcUrl,
        chain: this.chain,
        account: owner,
        nft,
        operator,
      });
    },
  };

  // ----- NFT
  nft = {
    makeOriginalNFT: (p: {
      workId: bigint;
      amount: bigint | number;
      split?: Address;
    }) =>
      rawNft.makeOriginalNFT({
        rpcUrl: this.rpcUrl,
        chain: this.chain,
        account: this.ensureAccount(),
        nft: this.addresses.NFT,
        ...p,
      }),
    makeDerivativeNFT: (p: {
      parentTokenId: bigint;
      childWorkId: bigint;
      upstreamBps: number;
      amount: bigint | number;
    }) =>
      rawNft.makeDerivativeNFT({
        rpcUrl: this.rpcUrl,
        chain: this.chain,
        account: this.ensureAccount(),
        nft: this.addresses.NFT,
        ...p,
      }),
    createOriginalWork: (p: {
      workId: bigint;
      creator: Address;
      split?: Address;
    }) =>
      rawNft.createOriginalWork({
        rpcUrl: this.rpcUrl,
        chain: this.chain,
        account: this.ensureAccount(),
        nft: this.addresses.NFT,
        ...p,
      }),
    mintEditionBatch: (p: {
      to: Address;
      workId: bigint;
      amount: number | bigint;
    }) =>
      rawNft.mintEditionBatch({
        rpcUrl: this.rpcUrl,
        chain: this.chain,
        account: this.ensureAccount(),
        nft: this.addresses.NFT,
        ...p,
      }),
    createDerivativeWork: (p: {
      parentTokenId: bigint;
      childWorkId: bigint;
      childCreator: Address;
      upstreamBps: number;
    }) =>
      rawNft.createDerivativeWork({
        rpcUrl: this.rpcUrl,
        chain: this.chain,
        account: this.ensureAccount(),
        nft: this.addresses.NFT,
        ...p,
      }),
    mintDerivativeEditionBatch: (p: {
      to: Address;
      childWorkId: bigint;
      parentTokenId: bigint;
      amount: number | bigint;
    }) =>
      rawNft.mintDerivativeEditionBatch({
        rpcUrl: this.rpcUrl,
        chain: this.chain,
        account: this.ensureAccount(),
        nft: this.addresses.NFT,
        ...p,
      }),
  };

  // ----- Market
  market = {
    list: (p: {
      tokenId: bigint;
      priceWei: bigint;
      isPrimary: boolean;
      nft?: Address;
      market?: Address;
    }) =>
      rawMarket.list({
        rpcUrl: this.rpcUrl,
        chain: this.chain,
        account: this.ensureAccount(),
        market: p.market ?? this.addresses.Market,
        nft: p.nft ?? this.addresses.NFT,
        tokenId: p.tokenId,
        priceWei: p.priceWei,
        isPrimary: p.isPrimary,
      }),
    buyNative: (p: {
      tokenId: bigint;
      valueWei: bigint;
      nft?: Address;
      market?: Address;
    }) =>
      rawMarket.buyNative({
        rpcUrl: this.rpcUrl,
        chain: this.chain,
        account: this.ensureAccount(),
        market: p.market ?? this.addresses.Market,
        nft: p.nft ?? this.addresses.NFT,
        tokenId: p.tokenId,
        valueWei: p.valueWei,
      }),
    getListing: (p: { tokenId: bigint; nft?: Address; market?: Address }) =>
      rawMarket.getListing({
        rpcUrl: this.rpcUrl,
        chain: this.chain,
        market: p.market ?? this.addresses.Market,
        nft: p.nft ?? this.addresses.NFT,
        tokenId: p.tokenId,
      }),
  };

  // ----- Split
  split = {
    create: (p: {
      upstream: Address;
      child: Address;
      bps: number;
      factory?: Address;
    }) =>
      rawSplit.create({
        rpcUrl: this.rpcUrl,
        chain: this.chain,
        account: this.ensureAccount(),
        factory: p.factory ?? (this.addresses.SplitFactory as Address),
        upstream: p.upstream,
        child: p.child,
        bps: p.bps,
      }),
  };
}

// 팩토리 함수
export function createClient(opts: ClientOptions) {
  return new Client(opts);
}
