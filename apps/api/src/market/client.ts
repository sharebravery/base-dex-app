import type { Bindings } from '../env';

const catalog = [
  { id: 'ethereum', symbol: 'ETH', name: 'Ethereum', binance: 'ETHUSDT', tradable: true },
  { id: 'bitcoin', symbol: 'BTC', name: 'Bitcoin', binance: 'BTCUSDT', tradable: false },
  { id: 'solana', symbol: 'SOL', name: 'Solana', binance: 'SOLUSDT', tradable: false },
  { id: 'usd-coin', symbol: 'USDC', name: 'USD Coin', binance: null, tradable: false },
] as const;

type Ticker = {
  symbol: string;
  lastPrice: string;
  priceChangePercent: string;
  quoteVolume: string;
};

export async function getMarkets(_env: Bindings) {
  const binanceSymbols = catalog
    .map((c) => c.binance)
    .filter((s): s is Exclude<(typeof catalog)[number]['binance'], null> => s !== null);
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
          tradable: c.tradable,
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
        tradable: c.tradable,
      };
    }),
  };
}
