import { Hono } from 'hono';
import type { Bindings } from '../env';
import { requestZeroX, USDC } from './client';
import type { SwapInput } from './client';
import { swapRequestSchema } from './schema';

export const swapRoutes = new Hono<{ Bindings: Bindings }>();

function normalize(
  kind: 'price' | 'quote',
  env: Bindings,
  input: SwapInput,
  provider: Awaited<ReturnType<typeof requestZeroX>>,
) {
  const allowanceTarget = provider.issues?.allowance?.spender;
  if (allowanceTarget && allowanceTarget.toLowerCase() !== env.ZEROX_ALLOWANCE_HOLDER.toLowerCase()) {
    throw new Error('unexpected_allowance_target');
  }
  if (kind === 'quote') {
    if (!provider.transaction) throw new Error('missing_transaction');
    if (provider.transaction.to.toLowerCase() !== env.ZEROX_SETTLER.toLowerCase()) {
      throw new Error('unexpected_transaction_target');
    }
    if (input.sellToken.toLowerCase() === USDC.toLowerCase() && allowanceTarget == null) {
      throw new Error('missing_allowance_target');
    }
  }
  return {
    sellAmount: provider.sellAmount,
    buyAmount: provider.buyAmount,
    minBuyAmount: provider.minBuyAmount ?? provider.buyAmount,
    networkFee: provider.totalNetworkFee,
    allowanceTarget: allowanceTarget ?? null,
    transactionTo: provider.transaction?.to ?? null,
    transactionData: provider.transaction?.data ?? null,
    transactionValue: provider.transaction?.value ?? '0',
    gas: provider.transaction?.gas ?? '0',
    gasPrice: provider.transaction?.gasPrice ?? '0',
    routeLabels: provider.route?.fills.map((fill) => fill.source) ?? [],
    fetchedAt: new Date().toISOString(),
    validForSeconds: kind === 'quote' ? 15 : 10,
  };
}

for (const kind of ['price', 'quote'] as const) {
  swapRoutes.post(`/swap/${kind}`, async (context) => {
    try {
      const input = swapRequestSchema.parse(await context.req.json());
      const provider = await requestZeroX(context.env, kind, input);
      return context.json(normalize(kind, context.env, input, provider));
    } catch (error) {
      const message = error instanceof Error ? error.message : 'invalid_request';
      return context.json({ error: message }, 400);
    }
  });
}
