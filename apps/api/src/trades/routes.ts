import { desc, eq } from 'drizzle-orm';
import { Hono } from 'hono';
import { z } from 'zod';
import type { Bindings } from '../env';
import { requireAppSession, type AuthVariables } from '../auth/middleware';
import { withDb } from '../db/client';
import { appTrades, profiles } from '../db/schema';
import {
  decodeUsdcDirection,
  validateVerifiedTrade,
  type RpcLog,
} from './verifier';

export const tradeRoutes = new Hono<{
  Bindings: Bindings;
  Variables: AuthVariables;
}>();
tradeRoutes.use('*', requireAppSession);

const verifySchema = z.object({
  txHash: z.string().regex(/^0x[a-fA-F0-9]{64}$/),
});

async function rpc<T>(env: Bindings, method: string, params: unknown[]) {
  const response = await fetch(env.BASE_RPC_URL, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ jsonrpc: '2.0', id: 1, method, params }),
  });
  if (!response.ok) throw new Error(`rpc_http_${response.status}`);
  const payload = (await response.json()) as { result: T | null };
  if (payload.result == null) throw new Error('rpc_result_missing');
  return payload.result;
}

tradeRoutes.post('/trades/verify', async (context) => {
  const { txHash } = verifySchema.parse(await context.req.json());
  const receipt = await rpc<{
    status: string;
    from: string;
    to: string;
    blockNumber: string;
    logs: RpcLog[];
  }>(context.env, 'eth_getTransactionReceipt', [txHash]);
  const transaction = await rpc<{
    value: string;
  }>(context.env, 'eth_getTransactionByHash', [txHash]);

  const walletAddress = context.get('walletAddress');
  validateVerifiedTrade({
    chainId: 8453,
    status: Number.parseInt(receipt.status, 16),
    from: receipt.from,
    to: receipt.to,
    authenticatedWallet: walletAddress,
    allowedSettler: context.env.ZEROX_SETTLER,
  });

  const direction = decodeUsdcDirection({
    logs: receipt.logs,
    walletAddress,
    usdcAddress: context.env.BASE_USDC_ADDRESS,
  });

  const profile = await withDb(context.env, async (db) => {
    const rows = await db
      .select()
      .from(profiles)
      .where(eq(profiles.walletAddress, walletAddress))
      .limit(1);
    return rows[0];
  });
  if (!profile) return context.json({ error: 'profile_not_found' }, 404);

  const nativeValue = BigInt(transaction.value);
  const record =
    direction.side === 'buy_eth'
      ? {
          sellToken: context.env.BASE_USDC_ADDRESS,
          buyToken: 'native:8453',
          sellAmount: direction.usdcAmount,
          buyAmount: null,
        }
      : {
          sellToken: 'native:8453',
          buyToken: context.env.BASE_USDC_ADDRESS,
          sellAmount: nativeValue,
          buyAmount: direction.usdcAmount,
        };

  await withDb(context.env, (db) =>
    db
      .insert(appTrades)
      .values({
        profileId: profile.id,
        chainId: 8453,
        txHash,
        ...record,
        metadata: {
          side: direction.side,
          receiptBlock: receipt.blockNumber,
          nativeBuyAmountUnavailable: direction.side === 'buy_eth',
        },
        executedAt: new Date(),
      })
      .onConflictDoNothing(),
  );

  return context.json({ txHash, verified: true, side: direction.side });
});

tradeRoutes.get('/trades', async (context) => {
  const profile = await withDb(context.env, async (db) => {
    const rows = await db
      .select()
      .from(profiles)
      .where(eq(profiles.walletAddress, context.get('walletAddress')))
      .limit(1);
    return rows[0];
  });
  if (!profile) return context.json({ error: 'profile_not_found' }, 404);

  const rows = await withDb(context.env, (db) =>
    db
      .select()
      .from(appTrades)
      .where(eq(appTrades.profileId, profile.id))
      .orderBy(desc(appTrades.executedAt))
      .limit(100),
  );
  return context.json({ trades: rows });
});
