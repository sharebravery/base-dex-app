import type { Bindings } from '../env';
import { providerMarketsSchema } from './schema';

const catalog = new Map([
  ['ethereum', true],
  ['bitcoin', false],
  ['solana', false],
  ['usd-coin', false],
  ['aerodrome-finance', false],
  ['degen-base', false],
]);

export async function getMarkets(env: Bindings) {
  const ids = [...catalog.keys()].join(',');
  const url = new URL(`${env.MARKET_API_BASE_URL}/coins/markets`);
  url.searchParams.set('vs_currency', 'usd');
  url.searchParams.set('ids', ids);
  url.searchParams.set('price_change_percentage', '24h');

  const response = await fetch(url, {
    headers: env.MARKET_API_KEY
      ? { 'x-cg-demo-api-key': env.MARKET_API_KEY }
      : undefined,
  });
  if (!response.ok) throw new Error(`market provider ${response.status}`);
  const parsed = providerMarketsSchema.parse(await response.json());

  return {
    assets: parsed.map((asset) => ({
      id: asset.id,
      symbol: asset.symbol.toUpperCase(),
      name: asset.name,
      priceUsd: String(asset.current_price),
      change24hPercent: String(asset.price_change_percentage_24h ?? 0),
      volume24hUsd: String(asset.total_volume),
      tradable: catalog.get(asset.id) === true,
    })),
  };
}
