import { afterEach, describe, expect, it, vi } from 'vitest';
import app from '../src/index';

afterEach(() => vi.restoreAllMocks());

describe('market routes', () => {
  it('normalizes Binance ticker data into curated catalog', async () => {
    vi.spyOn(globalThis, 'fetch').mockResolvedValueOnce(
      new Response(
        JSON.stringify([
          {
            symbol: 'ETHUSDT',
            lastPrice: '3240.12',
            priceChangePercent: '2.41',
            quoteVolume: '812000000',
          },
          {
            symbol: 'BTCUSDT',
            lastPrice: '97500.00',
            priceChangePercent: '-0.82',
            quoteVolume: '3200000000',
          },
          {
            symbol: 'SOLUSDT',
            lastPrice: '188.40',
            priceChangePercent: '1.12',
            quoteVolume: '410000000',
          },
        ]),
        { status: 200 },
      ),
    );

    const response = await app.request('/v1/markets', {}, {
      APP_ENV: 'mock',
      MARKET_API_BASE_URL: 'https://example.test/api/v3',
    });
    expect(response.status).toBe(200);
    expect(await response.json()).toEqual({
      assets: [
        {
          id: 'ethereum',
          symbol: 'ETH',
          name: 'Ethereum',
          priceUsd: '3240.12',
          change24hPercent: '2.41',
          volume24hUsd: '812000000',
          tradable: true,
        },
        {
          id: 'bitcoin',
          symbol: 'BTC',
          name: 'Bitcoin',
          priceUsd: '97500.00',
          change24hPercent: '-0.82',
          volume24hUsd: '3200000000',
          tradable: false,
        },
        {
          id: 'solana',
          symbol: 'SOL',
          name: 'Solana',
          priceUsd: '188.40',
          change24hPercent: '1.12',
          volume24hUsd: '410000000',
          tradable: false,
        },
        {
          id: 'usd-coin',
          symbol: 'USDC',
          name: 'USD Coin',
          priceUsd: '1.00',
          change24hPercent: '0.00',
          volume24hUsd: '0',
          tradable: false,
        },
      ],
    });
    expect(fetch).toHaveBeenCalledWith(
      expect.objectContaining({
        href: expect.stringContaining('api.binance.com/api/v3/ticker/24hr'),
      }),
    );
  });
});
