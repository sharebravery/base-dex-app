import { Hono } from 'hono';
import type { Bindings } from '../env';
import {
  getCandles,
  getMarkets,
  getRecentTrades,
  getSparklines,
  isCandleInterval,
} from './client';

export const marketRoutes = new Hono<{ Bindings: Bindings }>();

marketRoutes.get('/markets', async (context) => {
  const result = await getMarkets(context.env);
  return context.json(result, 200, {
    'Cache-Control': 'public, max-age=10, stale-while-revalidate=20',
  });
});

marketRoutes.get('/candles', async (context) => {
  const assetId = context.req.query('assetId') ?? '';
  const interval = context.req.query('interval') ?? '';
  if (!isCandleInterval(interval)) {
    return context.json({ error: 'unsupported_interval' }, 400);
  }
  try {
    const candles = await getCandles(context.env, assetId, interval);
    return context.json(
      { candles },
      200,
      // 1d bars refresh at UTC midnight, 1h bars each hour — cache liberally
      // so repeat opens of the pair detail chart are instant.
      { 'Cache-Control': 'public, max-age=60, stale-while-revalidate=300' },
    );
  } catch (error) {
    const message = error instanceof Error ? error.message : 'internal_error';
    const isClientError =
      message === 'unknown_asset' || message === 'no_candles_for_asset';
    return context.json({ error: message }, isClientError ? 400 : 502);
  }
});

// 7d sparklines for the market list. 4h bars × 42 points × ~20 assets. Cached
// generously — the list tile chart is decorative, not a trading signal, so
// stale values are perfectly fine.
marketRoutes.get('/sparklines', async (context) => {
  const sparklines = await getSparklines(context.env);
  return context.json({ sparklines }, 200, {
    'Cache-Control': 'public, max-age=300, stale-while-revalidate=900',
  });
});

// Recent-trade tape for the pair-detail screen. Cached only for a few
// seconds — the whole point of the tape is that it changes.
marketRoutes.get('/trades/recent', async (context) => {
  const assetId = context.req.query('assetId') ?? '';
  const rawLimit = context.req.query('limit');
  const limit = rawLimit ? Number.parseInt(rawLimit, 10) : 30;
  if (!Number.isFinite(limit)) {
    return context.json({ error: 'invalid_limit' }, 400);
  }
  try {
    const trades = await getRecentTrades(context.env, assetId, limit);
    return context.json({ trades }, 200, {
      'Cache-Control': 'public, max-age=3, stale-while-revalidate=10',
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'internal_error';
    const isClientError =
      message === 'unknown_asset' || message === 'no_trades_for_asset';
    return context.json({ error: message }, isClientError ? 400 : 502);
  }
});
