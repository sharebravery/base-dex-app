import { afterEach, describe, expect, it, vi } from 'vitest';
import app from '../src/index';

afterEach(() => vi.restoreAllMocks());

describe('market routes', () => {
  it('normalizes current market data', async () => {
    vi.spyOn(globalThis, 'fetch').mockResolvedValueOnce(
      new Response(JSON.stringify([
        {
          id: 'ethereum',
          symbol: 'eth',
          name: 'Ethereum',
          current_price: 3240.12,
          price_change_percentage_24h: 2.41,
          total_volume: 812000000
        }
      ]), { status: 200 }),
    );

    const response = await app.request('/v1/markets', {}, {
      APP_ENV: 'mock',
      MARKET_API_BASE_URL: 'https://example.test/api/v3',
    });
    expect(response.status).toBe(200);
    expect(await response.json()).toEqual({
      assets: [{
        id: 'ethereum',
        symbol: 'ETH',
        name: 'Ethereum',
        priceUsd: '3240.12',
        change24hPercent: '2.41',
        volume24hUsd: '812000000',
        tradable: true
      }]
    });
    expect(fetch).toHaveBeenCalledWith(
      expect.objectContaining({
        href: expect.stringContaining('/api/v3/coins/markets'),
      }),
      expect.anything(),
    );
  });
});
