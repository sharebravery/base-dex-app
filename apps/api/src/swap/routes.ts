import { Hono } from 'hono';
import type { Bindings } from '../env';
import { requestKyberSwap, USDC } from './client';
import type { SwapInput } from './client';
import { swapRequestSchema } from './schema';

export const swapRoutes = new Hono<{ Bindings: Bindings }>();

type KyberResponse = Awaited<ReturnType<typeof requestKyberSwap>>;

/**
 * Map a KyberSwap `routeSummary` onto the shape the mobile client already
 * consumes (`SwapPrice` / `SwapQuote`).
 *
 * KyberSwap does not return `minBuyAmount` — we compute it here from the
 * caller's `slippageBps` so the mobile confirmation sheet has a firm floor.
 *
 * `route` is a 2-D array: outer parallel-split × inner sequential hops.
 * We flatten it into a deduped list of exchange labels for display.
 */
function normalize(
  kind: 'price' | 'quote',
  input: SwapInput,
  data: KyberResponse,
) {
  const summary = data.routeSummary;
  const buyAmount = BigInt(summary.amountOut);
  // slippage floor: buy * (10000 - bps) / 10000, integer math to stay exact.
  const minBuyAmount =
    (buyAmount * BigInt(10000 - input.slippageBps)) / BigInt(10000);

  // Prefer L1+L2 fee in USD when available; otherwise fall back to gas * gasPrice
  // in wei (rare — KyberSwap almost always returns gasUsd on Base).
  const gasWei = BigInt(summary.gas) * BigInt(summary.gasPrice ?? '0');
  const networkFee = gasWei.toString();

  const routeLabels = Array.from(
    new Set(summary.route.flat().map((hop) => hop.exchange)),
  );

  return {
    sellAmount: summary.amountIn,
    buyAmount: summary.amountOut,
    minBuyAmount: minBuyAmount.toString(),
    networkFee,
    // KyberSwap: token approvals go to the router itself (not a separate holder).
    // Only relevant for USDC sells; ETH sells need no allowance.
    allowanceTarget:
      input.sellToken.toLowerCase() === USDC.toLowerCase()
        ? data.routerAddress
        : null,
    transactionTo: data.routerAddress,
    // We never sign on-chain; expose calldata as null so the mobile client
    // renders "Demo — not broadcast" instead of a fake tx blob.
    transactionData: null,
    transactionValue: '0',
    gas: summary.gas,
    gasPrice: summary.gasPrice ?? '0',
    routeLabels,
    fetchedAt: new Date().toISOString(),
    // KyberSwap docs recommend caching < 5–10s; use 8 for quote, 6 for price
    // to leave headroom for the confirm tap.
    validForSeconds: kind === 'quote' ? 8 : 6,
  };
}

for (const kind of ['price', 'quote'] as const) {
  swapRoutes.post(`/swap/${kind}`, async (context) => {
    try {
      const input = swapRequestSchema.parse(await context.req.json());
      const data = await requestKyberSwap(context.env, input);
      return context.json(normalize(kind, input, data));
    } catch (error) {
      const message = error instanceof Error ? error.message : 'invalid_request';
      return context.json({ error: message }, 400);
    }
  });
}
