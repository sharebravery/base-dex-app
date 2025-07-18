import { Hono } from 'hono';
import type { Bindings } from '../env';
import { getMarkets } from './client';

export const marketRoutes = new Hono<{ Bindings: Bindings }>();

marketRoutes.get('/markets', async (context) => {
  const result = await getMarkets(context.env);
  return context.json(result, 200, {
    'Cache-Control': 'public, max-age=10, stale-while-revalidate=20',
  });
});

marketRoutes.get('/candles', async (context) => {
  const assetId = context.req.query('assetId');
  const interval = context.req.query('interval');
  if (assetId !== 'ethereum' || !['1d', '7d', '30d'].includes(interval ?? '')) {
    return context.json({ error: 'unsupported_candle_request' }, 400);
  }
  return context.json({ candles: [] });
});
