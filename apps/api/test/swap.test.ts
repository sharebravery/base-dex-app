import { afterEach, describe, expect, it, vi } from 'vitest';
import app from '../src/index';

const USDC = '0x833589fCD6eDb6E08f4c7C32D4f71b54bDa02913';
const ETH = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE';
const ROUTER = '0x6131B5fae19EA4f9D964eAc0408E4408b66337b5';

const env = {
  APP_ENV: 'mock' as const,
  MARKET_API_BASE_URL: 'https://market.test',
  KYBERSWAP_CLIENT_ID: 'dex-demo-test',
};

/** A minimal but valid KyberSwap `routeSummary` reply for USDC -> ETH. */
const kyberOk = {
  code: 0,
  message: 'successfully',
  data: {
    routeSummary: {
      tokenIn: USDC.toLowerCase(),
      tokenOut: ETH.toLowerCase(),
      amountIn: '100000000',
      amountInUsd: '100.00',
      amountOut: '54169181712797488',
      amountOutUsd: '100.02',
      gas: '350000',
      gasPrice: '15000000',
      gasUsd: '0.01',
      l1FeeUsd: '0.00003',
      route: [
        [
          {
            pool: '0xdd722e12e9a6763e96b5c5cf45e5fbc1243e15e2',
            tokenIn: USDC.toLowerCase(),
            tokenOut: '0xfde4c96c8593536e31f229ea8f37b2ada2699bb2',
            swapAmount: '100000000',
            amountOut: '100190816',
            exchange: 'curve-stable-ng',
          },
          {
            pool: '0x9785ef59e2b499fb741674ecf6faf912df7b3c1b',
            tokenIn: '0xfde4c96c8593536e31f229ea8f37b2ada2699bb2',
            tokenOut: '0x4200000000000000000000000000000000000006',
            swapAmount: '100190816',
            amountOut: '54169181712797488',
            exchange: 'aerodrome-cl',
          },
        ],
      ],
      routeID: 'test-route-id',
      checksum: 'test-checksum',
      timestamp: 1784257275,
    },
    routerAddress: ROUTER,
  },
};

afterEach(() => vi.restoreAllMocks());

describe('swap proxy (KyberSwap)', () => {
  it('rejects a non-curated pair before provider access', async () => {
    const fetchSpy = vi.spyOn(globalThis, 'fetch');
    const response = await app.request('/v1/swap/price', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        chainId: 8453,
        sellToken: '0x0000000000000000000000000000000000009999',
        buyToken: USDC,
        sellAmount: '1000000',
        taker: '0x1111111111111111111111111111111111111111',
        slippageBps: 50,
      }),
    }, env);
    expect(response.status).toBe(400);
    expect(fetchSpy).not.toHaveBeenCalled();
  });

  it('normalizes a quote, computes minBuyAmount from slippageBps, and exposes routerAddress', async () => {
    const fetchSpy = vi
      .spyOn(globalThis, 'fetch')
      .mockResolvedValueOnce(new Response(JSON.stringify(kyberOk), { status: 200 }));

    const response = await app.request('/v1/swap/quote', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        chainId: 8453,
        sellToken: USDC,
        buyToken: ETH,
        sellAmount: '100000000',
        taker: '0x1111111111111111111111111111111111111111',
        slippageBps: 50,
      }),
    }, env);
    expect(response.status).toBe(200);
    const json = (await response.json()) as Record<string, unknown>;

    // KyberSwap URL + x-client-id header.
    expect(fetchSpy).toHaveBeenCalledOnce();
    const [calledUrl, calledInit] = fetchSpy.mock.calls[0]!;
    expect(String(calledUrl)).toContain('aggregator-api.kyberswap.com/base/api/v1/routes');
    expect((calledInit as RequestInit).headers).toMatchObject({
      'x-client-id': 'dex-demo-test',
    });

    expect(json.sellAmount).toBe('100000000');
    expect(json.buyAmount).toBe('54169181712797488');
    // 50 bps floor: 54169181712797488 * 9950 / 10000 = 53898335804233500
    expect(json.minBuyAmount).toBe('53898335804233500');
    // USDC sell → approval goes to the router itself.
    expect(json.allowanceTarget).toBe(ROUTER);
    expect(json.transactionTo).toBe(ROUTER);
    // Never signs; calldata is omitted for transparency.
    expect(json.transactionData).toBeNull();
    // Route labels flattened + deduped.
    expect(json.routeLabels).toEqual(['curve-stable-ng', 'aerodrome-cl']);
    expect(json.validForSeconds).toBe(8);
  });

  it('omits allowanceTarget when selling ETH (native, no approval required)', async () => {
    vi.spyOn(globalThis, 'fetch').mockResolvedValueOnce(
      new Response(
        JSON.stringify({
          ...kyberOk,
          data: {
            ...kyberOk.data,
            routeSummary: {
              ...kyberOk.data.routeSummary,
              tokenIn: ETH.toLowerCase(),
              tokenOut: USDC.toLowerCase(),
            },
          },
        }),
        { status: 200 },
      ),
    );

    const response = await app.request('/v1/swap/quote', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        chainId: 8453,
        sellToken: ETH,
        buyToken: USDC,
        sellAmount: '1000000000000000000',
        taker: '0x1111111111111111111111111111111111111111',
        slippageBps: 50,
      }),
    }, env);
    expect(response.status).toBe(200);
    const json = (await response.json()) as Record<string, unknown>;
    expect(json.allowanceTarget).toBeNull();
    expect(json.transactionTo).toBe(ROUTER);
  });

  it('surfaces upstream KyberSwap failures as 4xx', async () => {
    vi.spyOn(globalThis, 'fetch').mockResolvedValueOnce(
      new Response(
        JSON.stringify({
          code: 4000,
          message: 'bad request',
          details: [{ field: 'tokenIn', description: 'identical with tokenOut' }],
        }),
        { status: 400 },
      ),
    );
    const response = await app.request('/v1/swap/price', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        chainId: 8453,
        sellToken: USDC,
        buyToken: ETH,
        sellAmount: '100000000',
        taker: '0x1111111111111111111111111111111111111111',
        slippageBps: 50,
      }),
    }, env);
    expect(response.status).toBe(400);
    const json = (await response.json()) as Record<string, unknown>;
    expect(String(json.error)).toMatch(/kyber_/);
  });

  it('accepts non-address pool identifiers (WETH wrap, native adapters)', async () => {
    // Some KyberSwap hops return non-`0x…` pool ids (wrap-native adapters,
    // bridge intermediaries). We must not reject those — we only surface
    // `exchange` to the client.
    vi.spyOn(globalThis, 'fetch').mockResolvedValueOnce(
      new Response(
        JSON.stringify({
          ...kyberOk,
          data: {
            ...kyberOk.data,
            routeSummary: {
              ...kyberOk.data.routeSummary,
              route: [
                [
                  {
                    ...kyberOk.data.routeSummary.route[0]![0]!,
                    pool: 'wrapped-native-adapter',
                    exchange: 'wrapped-native',
                  },
                ],
              ],
            },
          },
        }),
        { status: 200 },
      ),
    );

    const response = await app.request('/v1/swap/price', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        chainId: 8453,
        sellToken: USDC,
        buyToken: ETH,
        sellAmount: '100000000',
        taker: '0x1111111111111111111111111111111111111111',
        slippageBps: 50,
      }),
    }, env);
    expect(response.status).toBe(200);
    const json = (await response.json()) as Record<string, unknown>;
    expect(json.routeLabels).toEqual(['wrapped-native']);
  });
});
