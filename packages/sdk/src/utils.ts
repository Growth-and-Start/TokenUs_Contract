export const MAX_BPS = 10_000;
export const toWei = (eth: string) => BigInt(Math.round(parseFloat(eth) * 1e18));
export const toBps = (pct: number) => Math.round(pct * 100);
