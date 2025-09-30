import { z } from 'zod';

const address = z.string().regex(/^0x[a-fA-F0-9]{40}$/);
const uintString = z.string().regex(/^\d+$/).refine((value) => BigInt(value) > 0n);

export const swapRequestSchema = z.object({
  chainId: z.literal(8453),
  sellToken: address,
  buyToken: address,
  sellAmount: uintString,
  taker: address,
  slippageBps: z.number().int().min(10).max(300),
});

/**
 * Subset of KyberSwap `/base/api/v1/routes` we care about.
 * See docs.kyberswap.com/developer-guide/aggregator-api → EVM Swaps.
 *
 * We deliberately DO NOT constrain `pool` to a `0x…` address regex — some
 * hops (WETH wrap, native-token intermediaries, bridge-style adapters)
 * return non-address pool identifiers, and we only surface `exchange` to
 * the UI anyway.
 */
const routeHopSchema = z.object({
  pool: z.string(),
  tokenIn: address,
  tokenOut: address,
  swapAmount: z.string(),
  amountOut: z.string(),
  exchange: z.string(),
});

export const kyberRouteSummarySchema = z.object({
  tokenIn: address,
  tokenOut: address,
  amountIn: z.string(),
  amountInUsd: z.string().optional(),
  amountOut: z.string(),
  amountOutUsd: z.string().optional(),
  gas: z.string(),
  gasPrice: z.string().optional(),
  gasUsd: z.string().optional(),
  l1FeeUsd: z.string().optional(),
  route: z.array(z.array(routeHopSchema)),
  routeID: z.string(),
  checksum: z.string(),
  timestamp: z.number(),
});

export const kyberRoutesResponseSchema = z.object({
  code: z.number(),
  message: z.string().optional(),
  data: z.object({
    routeSummary: kyberRouteSummarySchema,
    routerAddress: address,
  }),
});
