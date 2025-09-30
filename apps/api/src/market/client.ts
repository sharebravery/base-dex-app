import type { Bindings } from '../env';

/**
 * Curated asset catalog for the demo.
 *
 * Only ETH/USDC is `tradable` (KyberSwap on Base). The rest are market-only —
 * we show price/volume/sparklines so the market screen looks like a real
 * exchange, but the Swap CTA on their pair-detail is disabled.
 *
 * `category` drives the segmented filter chips on the market screen. An asset
 * can only sit in one bucket; pick the bucket most users would look under.
 */
export const catalog = [
  // Layer 1
  { id: 'bitcoin', symbol: 'BTC', name: 'Bitcoin', binance: 'BTCUSDT', tradable: false, category: 'layer1' },
  { id: 'ethereum', symbol: 'ETH', name: 'Ethereum', binance: 'ETHUSDT', tradable: true, category: 'layer1' },
  { id: 'solana', symbol: 'SOL', name: 'Solana', binance: 'SOLUSDT', tradable: false, category: 'layer1' },
  { id: 'bnb', symbol: 'BNB', name: 'BNB', binance: 'BNBUSDT', tradable: false, category: 'layer1' },
  { id: 'xrp', symbol: 'XRP', name: 'XRP', binance: 'XRPUSDT', tradable: false, category: 'layer1' },
  { id: 'cardano', symbol: 'ADA', name: 'Cardano', binance: 'ADAUSDT', tradable: false, category: 'layer1' },
  { id: 'avalanche', symbol: 'AVAX', name: 'Avalanche', binance: 'AVAXUSDT', tradable: false, category: 'layer1' },
  { id: 'toncoin', symbol: 'TON', name: 'Toncoin', binance: 'TONUSDT', tradable: false, category: 'layer1' },
  { id: 'sui', symbol: 'SUI', name: 'Sui', binance: 'SUIUSDT', tradable: false, category: 'layer1' },
  { id: 'aptos', symbol: 'APT', name: 'Aptos', binance: 'APTUSDT', tradable: false, category: 'layer1' },

  // Layer 2 / rollups
  { id: 'arbitrum', symbol: 'ARB', name: 'Arbitrum', binance: 'ARBUSDT', tradable: false, category: 'layer2' },
  { id: 'optimism', symbol: 'OP', name: 'Optimism', binance: 'OPUSDT', tradable: false, category: 'layer2' },
  { id: 'polygon', symbol: 'MATIC', name: 'Polygon', binance: 'MATICUSDT', tradable: false, category: 'layer2' },

  // DeFi
  { id: 'chainlink', symbol: 'LINK', name: 'Chainlink', binance: 'LINKUSDT', tradable: false, category: 'defi' },
  { id: 'uniswap', symbol: 'UNI', name: 'Uniswap', binance: 'UNIUSDT', tradable: false, category: 'defi' },
  { id: 'aave', symbol: 'AAVE', name: 'Aave', binance: 'AAVEUSDT', tradable: false, category: 'defi' },

  // Meme
  { id: 'dogecoin', symbol: 'DOGE', name: 'Dogecoin', binance: 'DOGEUSDT', tradable: false, category: 'meme' },
  { id: 'shiba-inu', symbol: 'SHIB', name: 'Shiba Inu', binance: 'SHIBUSDT', tradable: false, category: 'meme' },
  { id: 'pepe', symbol: 'PEPE', name: 'Pepe', binance: 'PEPEUSDT', tradable: false, category: 'meme' },
  { id: 'bonk', symbol: 'BONK', name: 'Bonk', binance: 'BONKUSDT', tradable: false, category: 'meme' },

  // Stable — no ticker; kept last so the list ends on a stable
  { id: 'usd-coin', symbol: 'USDC', name: 'USD Coin', binance: null, tradable: false, category: 'stable' },
] as const;

export type CatalogEntry = (typeof catalog)[number];
export type AssetCategory = CatalogEntry['category'];

type Ticker = {
  symbol: string;
  lastPrice: string;
  priceChangePercent: string;
  quoteVolume: string;
  highPrice: string;
  lowPrice: string;
};

export async function getMarkets(_env: Bindings) {
  const binanceSymbols = catalog
    .map((c) => c.binance)
    .filter((s): s is Exclude<CatalogEntry['binance'], null> => s !== null);
  const symbolsParam = JSON.stringify(binanceSymbols);
  const url = new URL('https://api.binance.com/api/v3/ticker/24hr');
  url.searchParams.set('symbols', symbolsParam);

  const response = await fetch(url);
  if (!response.ok) throw new Error(`market_provider_${response.status}`);
  const tickers = (await response.json()) as Ticker[];
  const byBinance = new Map(tickers.map((t) => [t.symbol, t]));

  return {
    assets: catalog.map((c) => {
      if (c.binance === null) {
        return {
          id: c.id,
          symbol: c.symbol,
          name: c.name,
          priceUsd: '1.00',
          change24hPercent: '0.00',
          volume24hUsd: '0',
          high24hUsd: '1.00',
          low24hUsd: '1.00',
          tradable: c.tradable,
          category: c.category,
        };
      }
      const t = byBinance.get(c.binance);
      if (!t) throw new Error(`missing_ticker_${c.binance}`);
      return {
        id: c.id,
        symbol: c.symbol,
        name: c.name,
        priceUsd: t.lastPrice,
        change24hPercent: t.priceChangePercent,
        volume24hUsd: t.quoteVolume,
        high24hUsd: t.highPrice,
        low24hUsd: t.lowPrice,
        tradable: c.tradable,
        category: c.category,
      };
    }),
  };
}

/**
 * Interval config for `/v1/candles`.
 * - `1d`: 30 daily candles (~1 month view)
 * - `7d`: 168 hourly candles (1 week, hour resolution)
 * - `30d`: 720 hourly candles (30 days, hour resolution)
 *
 * Binance klines endpoint is public (weight 2/req, no key required).
 * Docs: developers.binance.com → REST /api/v3/klines
 */
const intervalConfig = {
  '1d': { binanceInterval: '1d', limit: 30 },
  '7d': { binanceInterval: '1h', limit: 168 },
  '30d': { binanceInterval: '1h', limit: 720 },
} as const;

export type CandleInterval = keyof typeof intervalConfig;

export function isCandleInterval(value: string): value is CandleInterval {
  return value === '1d' || value === '7d' || value === '30d';
}

/** A single normalized candle. Amounts are USD strings (Binance quote-in-USDT). */
export type Candle = {
  timestamp: string; // ISO 8601, open time
  open: string;
  high: string;
  low: string;
  close: string;
};

/** Raw Binance kline row: [openTime, open, high, low, close, volume, closeTime, ...]. */
type BinanceKline = [number, string, string, string, string, string, number, ...unknown[]];

export async function getCandles(
  _env: Bindings,
  assetId: string,
  interval: CandleInterval,
): Promise<Candle[]> {
  const entry = catalog.find((c) => c.id === assetId);
  if (!entry) throw new Error('unknown_asset');
  if (entry.binance === null) throw new Error('no_candles_for_asset');

  const { binanceInterval, limit } = intervalConfig[interval];
  const url = new URL('https://api.binance.com/api/v3/klines');
  url.searchParams.set('symbol', entry.binance);
  url.searchParams.set('interval', binanceInterval);
  url.searchParams.set('limit', String(limit));

  const response = await fetch(url);
  if (!response.ok) throw new Error(`candles_provider_${response.status}`);
  const rows = (await response.json()) as BinanceKline[];
  return rows.map((row) => ({
    timestamp: new Date(row[0]).toISOString(),
    open: row[1],
    high: row[2],
    low: row[3],
    close: row[4],
  }));
}

/**
 * Most recent trades for a catalog asset. Backed by Binance
 * `/api/v3/trades`, which is public and un-authenticated.
 *
 * The Binance shape is `{ id, price, qty, quoteQty, time, isBuyerMaker }`.
 * `isBuyerMaker=true` means the taker was a seller (aggressive sell) — we
 * expose it verbatim so the client can render a green/red tape without
 * making UX decisions here.
 */
export type RecentTrade = {
  id: number;
  price: string;
  qty: string;
  quoteQty: string;
  timestamp: string; // ISO 8601
  isBuyerMaker: boolean;
};

type BinanceTrade = {
  id: number;
  price: string;
  qty: string;
  quoteQty: string;
  time: number;
  isBuyerMaker: boolean;
};

export async function getRecentTrades(
  _env: Bindings,
  assetId: string,
  limit: number,
): Promise<RecentTrade[]> {
  const entry = catalog.find((c) => c.id === assetId);
  if (!entry) throw new Error('unknown_asset');
  if (entry.binance === null) throw new Error('no_trades_for_asset');

  // Binance caps at 1000; we intentionally keep the tape short (20-50).
  const clamped = Math.max(1, Math.min(100, limit));
  const url = new URL('https://api.binance.com/api/v3/trades');
  url.searchParams.set('symbol', entry.binance);
  url.searchParams.set('limit', String(clamped));

  const response = await fetch(url);
  if (!response.ok) throw new Error(`trades_provider_${response.status}`);
  const rows = (await response.json()) as BinanceTrade[];
  // Binance returns oldest-first — flip so the newest row is on top, which is
  // how every DEX/CEX tape reads.
  return rows.reverse().map((row) => ({
    id: row.id,
    price: row.price,
    qty: row.qty,
    quoteQty: row.quoteQty,
    timestamp: new Date(row.time).toISOString(),
    isBuyerMaker: row.isBuyerMaker,
  }));
}

/**
 * 7-day sparklines for every catalog asset with a Binance symbol.
 *
 * 42 points of 4h closes = one week. That's enough resolution for a nice
 * micro-chart in a list tile but small enough that we can fetch every asset
 * in parallel and still keep the response < 20 KB. Non-Binance assets get an
 * empty array (`usd-coin`).
 *
 * If a single provider request fails we return `[]` for that asset rather
 * than failing the whole request — a missing sparkline degrades gracefully.
 */
export async function getSparklines(
  _env: Bindings,
): Promise<Record<string, string[]>> {
  const entries = catalog.filter(
    (c): c is CatalogEntry & { binance: string } => c.binance !== null,
  );
  const results = await Promise.all(
    entries.map(async (c) => {
      try {
        const url = new URL('https://api.binance.com/api/v3/klines');
        url.searchParams.set('symbol', c.binance);
        url.searchParams.set('interval', '4h');
        url.searchParams.set('limit', '42');
        const response = await fetch(url);
        if (!response.ok) return [c.id, [] as string[]] as const;
        const rows = (await response.json()) as BinanceKline[];
        return [c.id, rows.map((r) => r[4])] as const;
      } catch {
        return [c.id, [] as string[]] as const;
      }
    }),
  );
  const map: Record<string, string[]> = {};
  for (const [id, points] of results) map[id] = points;
  // Include USDC with an empty series so the client doesn't have to special-case.
  for (const c of catalog) if (!(c.id in map)) map[c.id] = [];
  return map;
}
