import type { Bindings } from '../env';
import { providerQuoteSchema } from './schema';

const ETH = '0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee';
export const USDC = '0x833589fcd6edb6e08f4c7c32d4f71b54bda02913';

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

export async function requestZeroX(
  env: Bindings,
  kind: 'price' | 'quote',
  input: SwapInput,
) {
  assertCuratedPair(input);
  const url = new URL(`/swap/allowance-holder/${kind}`, env.ZEROX_API_BASE_URL);
  for (const [key, value] of Object.entries({
    chainId: String(input.chainId),
    sellToken: input.sellToken,
    buyToken: input.buyToken,
    sellAmount: input.sellAmount,
    taker: input.taker,
    slippageBps: String(input.slippageBps),
  })) url.searchParams.set(key, value);

  const response = await fetch(url, {
    headers: { '0x-api-key': env.ZEROX_API_KEY, '0x-version': 'v2' },
  });
  if (!response.ok) throw new Error(`zero_x_${response.status}`);
  return providerQuoteSchema.parse(await response.json());
}
