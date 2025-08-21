import { afterEach, describe, expect, it, vi } from 'vitest';
import app from '../src/index';

const env = {
  APP_ENV: 'mock' as const,
  MARKET_API_BASE_URL: 'https://market.test',
  ZEROX_API_BASE_URL: 'https://api.0x.org',
  ZEROX_API_KEY: 'test-key',
  ZEROX_ALLOWANCE_HOLDER: '0x0000000000000000000000000000000000000001',
  ZEROX_SETTLER: '0x0000000000000000000000000000000000000002',
};

afterEach(() => vi.restoreAllMocks());

describe('swap proxy', () => {
  it('rejects a non-curated pair before provider access', async () => {
    const fetchSpy = vi.spyOn(globalThis, 'fetch');
    const response = await app.request('/v1/swap/price', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        chainId: 8453,
        sellToken: '0x0000000000000000000000000000000000009999',
        buyToken: '0x833589fCD6eDb6E08f4c7C32D4f71b54bDa02913',
        sellAmount: '1000000',
        taker: '0x1111111111111111111111111111111111111111',
        slippageBps: 50,
      }),
    }, env);
    expect(response.status).toBe(400);
    expect(fetchSpy).not.toHaveBeenCalled();
  });

  it('normalizes a firm quote and validates spender', async () => {
    vi.spyOn(globalThis, 'fetch').mockResolvedValueOnce(new Response(JSON.stringify({
      buyAmount: '300000000000000',
      minBuyAmount: '298500000000000',
      sellAmount: '1000000',
      totalNetworkFee: '10000000000000',
      issues: { allowance: { spender: env.ZEROX_ALLOWANCE_HOLDER } },
      transaction: {
        to: env.ZEROX_SETTLER,
        data: '0x1234',
        value: '0',
        gas: '220000',
        gasPrice: '1000000'
      },
      route: { fills: [{ source: 'Uniswap_V3' }] }
    }), { status: 200 }));

    const response = await app.request('/v1/swap/quote', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        chainId: 8453,
        sellToken: '0x833589fCD6eDb6E08f4c7C32D4f71b54bDa02913',
        buyToken: '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE',
        sellAmount: '1000000',
        taker: '0x1111111111111111111111111111111111111111',
        slippageBps: 50,
      }),
    }, env);

    expect(response.status).toBe(200);
    const json = await response.json() as Record<string, unknown>;
    expect(json.allowanceTarget).toBe(env.ZEROX_ALLOWANCE_HOLDER);
    expect(json.transactionTo).toBe(env.ZEROX_SETTLER);
  });
});
