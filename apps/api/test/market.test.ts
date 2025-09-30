import { afterEach, describe, expect, it, vi } from 'vitest';
import app from '../src/index';
import { catalog } from '../src/market/client';

afterEach(() => vi.restoreAllMocks());

// A synthetic ticker for every catalog entry that has a Binance symbol. We
// hand-craft the numbers so the test can assert the shape (and a couple of
// specific fields) without hard-coding every asset.
function tickerFixture() {
  return catalog
    .filter((c) => c.binance !== null)
    .map((c, i) => ({
      symbol: c.binance!,
      lastPrice: (100 + i).toFixed(2),
      priceChangePercent: (i % 2 === 0 ? 1.23 : -0.45).toFixed(2),
      quoteVolume: String(1_000_000 * (i + 1)),
      highPrice: (110 + i).toFixed(2),
      lowPrice: (90 + i).toFixed(2),
    }));
}

describe('market routes', () => {
  it('normalizes Binance ticker data across the curated catalog', async () => {
    vi.spyOn(globalThis, 'fetch').mockResolvedValueOnce(
      new Response(JSON.stringify(tickerFixture()), { status: 200 }),
    );

    const response = await app.request('/v1/markets', {}, {
      APP_ENV: 'mock',
      MARKET_API_BASE_URL: 'https://example.test/api/v3',
    });
    expect(response.status).toBe(200);
    const json = (await response.json()) as {
      assets: Array<{
        id: string;
        symbol: string;
        category: string;
        tradable: boolean;
        priceUsd: string;
        volume24hUsd: string;
      }>;
    };

    // Every catalog entry (including USDC) must appear.
    expect(json.assets).toHaveLength(catalog.length);

    // ETH is the only tradable asset (KyberSwap Base router only quotes
    // ETH/USDC). This is a load-bearing invariant elsewhere in the app.
    const tradable = json.assets.filter((a) => a.tradable);
    expect(tradable.map((a) => a.id)).toEqual(['ethereum']);

    // Categories must come through so the client can filter chips.
    const eth = json.assets.find((a) => a.id === 'ethereum')!;
    expect(eth.category).toBe('layer1');
    const uni = json.assets.find((a) => a.id === 'uniswap')!;
    expect(uni.category).toBe('defi');

    // USDC has no Binance symbol — we synthesize $1.00 / 0% / 0 volume so the
    // client doesn't have to special-case stables.
    const usdc = json.assets.find((a) => a.id === 'usd-coin')!;
    expect(usdc).toMatchObject({
      priceUsd: '1.00',
      volume24hUsd: '0',
    });

    // 24h high/low come from Binance's ticker payload.
    const btc = json.assets.find((a) => a.id === 'bitcoin')!;
    expect(btc.priceUsd).toBe('100.00');
    expect(btc).toMatchObject({ high24hUsd: '110.00', low24hUsd: '90.00' });

    expect(fetch).toHaveBeenCalledWith(
      expect.objectContaining({
        href: expect.stringContaining('api.binance.com/api/v3/ticker/24hr'),
      }),
    );
  });
});

describe('candle routes', () => {
  const kline = (t: number, o: string, h: string, l: string, c: string) =>
    [t, o, h, l, c, '0', t + 60_000, '0', 0, '0', '0', '0'] as const;

  it('returns normalized OHLC for a supported asset+interval', async () => {
    const fetchSpy = vi.spyOn(globalThis, 'fetch').mockResolvedValueOnce(
      new Response(
        JSON.stringify([
          kline(1784073600000, '1891.87', '1946.52', '1864.38', '1917.86'),
          kline(1784160000000, '1917.86', '1929.48', '1857.54', '1864.71'),
        ]),
        { status: 200 },
      ),
    );

    const response = await app.request('/v1/candles?assetId=ethereum&interval=1d');
    expect(response.status).toBe(200);
    const json = (await response.json()) as { candles: unknown[] };
    expect(json.candles).toEqual([
      {
        timestamp: '2026-07-15T00:00:00.000Z',
        open: '1891.87',
        high: '1946.52',
        low: '1864.38',
        close: '1917.86',
      },
      {
        timestamp: '2026-07-16T00:00:00.000Z',
        open: '1917.86',
        high: '1929.48',
        low: '1857.54',
        close: '1864.71',
      },
    ]);

    // Verifies we ask Binance for the right symbol/limit for the interval.
    const [calledUrl] = fetchSpy.mock.calls[0]!;
    const url = new URL(String(calledUrl));
    expect(url.hostname).toBe('api.binance.com');
    expect(url.searchParams.get('symbol')).toBe('ETHUSDT');
    expect(url.searchParams.get('interval')).toBe('1d');
    expect(url.searchParams.get('limit')).toBe('30');
  });

  it('uses hourly bars for 7d and 30d windows', async () => {
    const fetchSpy = vi
      .spyOn(globalThis, 'fetch')
      .mockResolvedValue(new Response(JSON.stringify([]), { status: 200 }));

    await app.request('/v1/candles?assetId=bitcoin&interval=7d');
    await app.request('/v1/candles?assetId=solana&interval=30d');
    const [urlA] = fetchSpy.mock.calls[0]!;
    const [urlB] = fetchSpy.mock.calls[1]!;
    expect(new URL(String(urlA)).searchParams.get('interval')).toBe('1h');
    expect(new URL(String(urlA)).searchParams.get('limit')).toBe('168');
    expect(new URL(String(urlA)).searchParams.get('symbol')).toBe('BTCUSDT');
    expect(new URL(String(urlB)).searchParams.get('interval')).toBe('1h');
    expect(new URL(String(urlB)).searchParams.get('limit')).toBe('720');
    expect(new URL(String(urlB)).searchParams.get('symbol')).toBe('SOLUSDT');
  });

  it('rejects an unsupported interval before touching the provider', async () => {
    const fetchSpy = vi.spyOn(globalThis, 'fetch');
    const response = await app.request('/v1/candles?assetId=ethereum&interval=42d');
    expect(response.status).toBe(400);
    expect(fetchSpy).not.toHaveBeenCalled();
  });

  it('rejects candles for non-catalog assets with 4xx', async () => {
    const fetchSpy = vi.spyOn(globalThis, 'fetch');
    const response = await app.request('/v1/candles?assetId=notreal&interval=1d');
    expect(response.status).toBe(400);
    expect(fetchSpy).not.toHaveBeenCalled();
  });

  it('rejects candles for assets without a Binance symbol (USDC)', async () => {
    const fetchSpy = vi.spyOn(globalThis, 'fetch');
    const response = await app.request('/v1/candles?assetId=usd-coin&interval=1d');
    expect(response.status).toBe(400);
    expect(fetchSpy).not.toHaveBeenCalled();
  });
});

describe('sparkline routes', () => {
  it('fans out one klines call per Binance-tracked asset and maps by id', async () => {
    // Fan-out fetch: return two closes per asset so we can assert both the
    // key and the value shape without threading real per-asset numbers.
    const fetchSpy = vi
      .spyOn(globalThis, 'fetch')
      .mockImplementation(async (input) => {
        const url = new URL(String(input));
        const sym = url.searchParams.get('symbol');
        // 42 rows expected in production; two are enough to prove the mapping.
        const rows = [
          [0, '0', '0', '0', `${sym}-a`, '0', 0, '0', 0, '0', '0', '0'],
          [1, '0', '0', '0', `${sym}-b`, '0', 1, '0', 0, '0', '0', '0'],
        ];
        return new Response(JSON.stringify(rows), { status: 200 });
      });

    const response = await app.request('/v1/sparklines');
    expect(response.status).toBe(200);
    const json = (await response.json()) as { sparklines: Record<string, string[]> };

    // Every catalog asset appears in the map — even USDC, which has no ticker
    // and gets an empty series so the client doesn't need to special-case it.
    for (const c of catalog) {
      expect(json.sparklines[c.id]).toBeDefined();
    }
    expect(json.sparklines['usd-coin']).toEqual([]);
    // Closes come from column index 4.
    expect(json.sparklines.ethereum).toEqual(['ETHUSDT-a', 'ETHUSDT-b']);

    // One provider call per Binance-tracked asset.
    const tracked = catalog.filter((c) => c.binance !== null).length;
    expect(fetchSpy).toHaveBeenCalledTimes(tracked);
  });

  it('returns an empty series for a single failing asset without failing the whole call', async () => {
    vi.spyOn(globalThis, 'fetch').mockImplementation(async (input) => {
      const url = new URL(String(input));
      if (url.searchParams.get('symbol') === 'BTCUSDT') {
        return new Response('boom', { status: 500 });
      }
      return new Response(JSON.stringify([]), { status: 200 });
    });

    const response = await app.request('/v1/sparklines');
    expect(response.status).toBe(200);
    const json = (await response.json()) as { sparklines: Record<string, string[]> };
    expect(json.sparklines.bitcoin).toEqual([]);
    expect(json.sparklines.ethereum).toEqual([]);
  });
});

describe('recent trades routes', () => {
  const binanceTrade = (
    id: number,
    price: string,
    qty: string,
    time: number,
    isBuyerMaker: boolean,
  ) => ({
    id,
    price,
    qty,
    quoteQty: String(Number.parseFloat(price) * Number.parseFloat(qty)),
    time,
    isBuyerMaker,
  });

  it('proxies Binance /trades and returns newest-first', async () => {
    // Binance returns oldest → newest; we flip so the newest row is index 0
    // (the way every tape reads).
    vi.spyOn(globalThis, 'fetch').mockResolvedValueOnce(
      new Response(
        JSON.stringify([
          binanceTrade(1, '3240.10', '0.5', 1_720_000_000_000, false),
          binanceTrade(2, '3240.55', '0.2', 1_720_000_010_000, true),
        ]),
        { status: 200 },
      ),
    );

    const response = await app.request(
      '/v1/trades/recent?assetId=ethereum&limit=5',
    );
    expect(response.status).toBe(200);
    const json = (await response.json()) as {
      trades: Array<{ id: number; timestamp: string; isBuyerMaker: boolean }>;
    };
    expect(json.trades).toHaveLength(2);
    expect(json.trades[0]!.id).toBe(2);
    expect(json.trades[1]!.id).toBe(1);
    expect(json.trades[0]!.timestamp).toBe('2024-07-03T09:46:50.000Z');
  });

  it('rejects trades for non-catalog assets with 4xx', async () => {
    const fetchSpy = vi.spyOn(globalThis, 'fetch');
    const response = await app.request('/v1/trades/recent?assetId=nope');
    expect(response.status).toBe(400);
    expect(fetchSpy).not.toHaveBeenCalled();
  });

  it('rejects trades for USDC (no Binance symbol)', async () => {
    const fetchSpy = vi.spyOn(globalThis, 'fetch');
    const response = await app.request(
      '/v1/trades/recent?assetId=usd-coin&limit=10',
    );
    expect(response.status).toBe(400);
    expect(fetchSpy).not.toHaveBeenCalled();
  });

  it('clamps a huge limit to 100 before calling Binance', async () => {
    const fetchSpy = vi
      .spyOn(globalThis, 'fetch')
      .mockResolvedValue(new Response(JSON.stringify([]), { status: 200 }));

    await app.request('/v1/trades/recent?assetId=bitcoin&limit=9999');
    const [calledUrl] = fetchSpy.mock.calls[0]!;
    expect(new URL(String(calledUrl)).searchParams.get('limit')).toBe('100');
  });
});
