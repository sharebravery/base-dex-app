import { z } from 'zod';

export const providerMarketSchema = z.object({
  id: z.string(),
  symbol: z.string(),
  name: z.string(),
  current_price: z.number().finite(),
  price_change_percentage_24h: z.number().finite().nullable(),
  total_volume: z.number().finite().nonnegative(),
});

export const providerMarketsSchema = z.array(providerMarketSchema);
