import { z } from 'zod';

const address = z.string().regex(/^0x[a-fA-F0-9]{40}$/);
const uintString = z.string().regex(/^\d+$/).refine((value) => BigInt(value) > 0n);

export const swapRequestSchema = z.object({
  chainId: z.literal(8453),
  sellToken: address,
  buyToken: address,
  sellAmount: uintString,
  taker: address,
  slippageBps: z.number().int().min(10).max(300),
});

export const providerQuoteSchema = z.object({
  buyAmount: z.string(),
  minBuyAmount: z.string().optional(),
  sellAmount: z.string(),
  totalNetworkFee: z.string().optional().default('0'),
  issues: z.object({
    allowance: z.object({ spender: address }).nullable().optional(),
  }).optional(),
  transaction: z.object({
    to: address,
    data: z.string().regex(/^0x[a-fA-F0-9]*$/),
    value: z.string(),
    gas: z.string(),
    gasPrice: z.string().optional(),
  }).optional(),
  route: z.object({
    fills: z.array(z.object({ source: z.string() })).default([]),
  }).optional(),
});
