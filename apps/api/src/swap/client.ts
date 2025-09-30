import type { Bindings } from '../env';
import { kyberRoutesResponseSchema } from './schema';

const ETH = '0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee';
export const USDC = '0x833589fcd6edb6e08f4c7c32d4f71b54bda02913';

const KYBER_BASE_URL = 'https://aggregator-api.kyberswap.com/base/api/v1/routes';

export type SwapInput = {
  chainId: 8453;
  sellToken: string;
  buyToken: string;
  sellAmount: string;
  taker: string;
  slippageBps: number;
};

export function assertCuratedPair(input: SwapInput) {
  const sell = input.sellToken.toLowerCase();
  const buy = input.buyToken.toLowerCase();
  const permitted = (sell === ETH && buy === USDC) || (sell === USDC && buy === ETH);
  if (!permitted) throw new Error('unsupported_pair');
}

/**
 * KyberSwap `/base/api/v1/routes` — free, no API key, requires an `x-client-id`.
 * Returns a `routeSummary` (fresh for ~5–10s) plus the router contract address.
 *
 * We only call this for BOTH "price" (indicative) and "quote" (firm-ish); the
 * quote leg does NOT hit `/route/build` because this demo never signs on-chain,
 * so we don't need transaction calldata. The routerAddress is exposed in the UI
 * as the would-be destination for transparency.
 */
export async function requestKyberSwap(env: Bindings, input: SwapInput) {
  assertCuratedPair(input);
  const url = new URL(KYBER_BASE_URL);
  url.searchParams.set('tokenIn', input.sellToken);
  url.searchParams.set('tokenOut', input.buyToken);
  url.searchParams.set('amountIn', input.sellAmount);
  const clientId = env.KYBERSWAP_CLIENT_ID?.trim() || 'dex-demo';
  const response = await fetch(url, {
    headers: {
      'x-client-id': clientId,
      // KyberSwap sits behind Cloudflare which challenges empty User-Agents
      // (Wrangler dev's default). A stable UA keeps us out of the JS
      // challenge path in both dev and production.
      'user-agent': `dex-demo/${clientId}`,
      accept: 'application/json',
    },
  });
  if (!response.ok) throw new Error(`kyber_${response.status}`);
  const parsed = kyberRoutesResponseSchema.parse(await response.json());
  if (parsed.code !== 0) throw new Error(parsed.message || 'kyber_bad_response');
  return parsed.data;
}
