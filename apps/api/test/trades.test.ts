import { describe, expect, it } from 'vitest';
import {
  decodeUsdcDirection,
  validateVerifiedTrade,
  type RpcLog,
} from '../src/trades/verifier';

const usdcAddress = '0x833589fCD6eDb6E08f4c7C32D4f71b54bDa02913';
const transferTopic =
  '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef';
const walletAddress = '0x1111111111111111111111111111111111111111';
const otherAddress = '0x2222222222222222222222222222222222222222';
const padTopic = (addr: string) =>
  '0x' + addr.slice(2).toLowerCase().padStart(64, '0');
const amountHex = '0x' + (1000000n).toString(16).padStart(64, '0');

describe('verified trade facts', () => {
  it('rejects a failed receipt', () => {
    expect(() =>
      validateVerifiedTrade({
        chainId: 8453,
        status: 0,
        from: '0x1111111111111111111111111111111111111111',
        to: '0x0000000000000000000000000000000000000002',
        authenticatedWallet: '0x1111111111111111111111111111111111111111',
        allowedSettler: '0x0000000000000000000000000000000000000002',
      }),
    ).toThrow('failed_receipt');
  });

  it('rejects a sender mismatch', () => {
    expect(() =>
      validateVerifiedTrade({
        chainId: 8453,
        status: 1,
        from: '0x2222222222222222222222222222222222222222',
        to: '0x0000000000000000000000000000000000000002',
        authenticatedWallet: '0x1111111111111111111111111111111111111111',
        allowedSettler: '0x0000000000000000000000000000000000000002',
      }),
    ).toThrow('sender_mismatch');
  });

  it('rejects an unexpected destination', () => {
    expect(() =>
      validateVerifiedTrade({
        chainId: 8453,
        status: 1,
        from: '0x1111111111111111111111111111111111111111',
        to: '0x9999999999999999999999999999999999999999',
        authenticatedWallet: '0x1111111111111111111111111111111111111111',
        allowedSettler: '0x0000000000000000000000000000000000000002',
      }),
    ).toThrow('unexpected_destination');
  });

  it('rejects a wrong chain id', () => {
    expect(() =>
      validateVerifiedTrade({
        chainId: 1,
        status: 1,
        from: '0x1111111111111111111111111111111111111111',
        to: '0x0000000000000000000000000000000000000002',
        authenticatedWallet: '0x1111111111111111111111111111111111111111',
        allowedSettler: '0x0000000000000000000000000000000000000002',
      }),
    ).toThrow('wrong_chain');
  });

  it('accepts a canonical Base 0x settler receipt', () => {
    expect(() =>
      validateVerifiedTrade({
        chainId: 8453,
        status: 1,
        from: '0x1111111111111111111111111111111111111111',
        to: '0x0000000000000000000000000000000000000002',
        authenticatedWallet: '0x1111111111111111111111111111111111111111',
        allowedSettler: '0x0000000000000000000000000000000000000002',
      }),
    ).not.toThrow();
  });
});

describe('decodeUsdcDirection', () => {
  it('decodes a buy_eth direction when wallet sends USDC', () => {
    const logs: RpcLog[] = [
      {
        address: usdcAddress,
        topics: [transferTopic, padTopic(walletAddress), padTopic(otherAddress)],
        data: amountHex,
      },
    ];
    const result = decodeUsdcDirection({ logs, walletAddress, usdcAddress });
    expect(result.side).toBe('buy_eth');
    expect(result.usdcAmount).toBe(1000000n);
  });

  it('decodes a sell_eth direction when wallet receives USDC', () => {
    const logs: RpcLog[] = [
      {
        address: usdcAddress,
        topics: [transferTopic, padTopic(otherAddress), padTopic(walletAddress)],
        data: amountHex,
      },
    ];
    const result = decodeUsdcDirection({ logs, walletAddress, usdcAddress });
    expect(result.side).toBe('sell_eth');
    expect(result.usdcAmount).toBe(1000000n);
  });

  it('throws when no USDC transfer log exists', () => {
    const logs: RpcLog[] = [
      {
        address: usdcAddress,
        topics: [
          '0x0000000000000000000000000000000000000000000000000000000000000000',
          padTopic(walletAddress),
          padTopic(otherAddress),
        ],
        data: amountHex,
      },
    ];
    expect(() => decodeUsdcDirection({ logs, walletAddress, usdcAddress })).toThrow(
      'missing_usdc_transfer',
    );
  });

  it('throws when the transfer log has a wrong contract address', () => {
    const logs: RpcLog[] = [
      {
        address: '0x9999999999999999999999999999999999999999',
        topics: [transferTopic, padTopic(walletAddress), padTopic(otherAddress)],
        data: amountHex,
      },
    ];
    expect(() => decodeUsdcDirection({ logs, walletAddress, usdcAddress })).toThrow(
      'missing_usdc_transfer',
    );
  });
});

// TODO(phase-4-followup): route-level integration coverage.
//
// The following cases exercise the full `POST /v1/trades/verify` route with
// mocked `fetch` for BASE_RPC_URL responses. They are gated behind `.skip`
// because they additionally require:
//   - a way to bypass or fake `requireAppSession` (currently expects a valid
//     Supabase-signed session JWT), and
//   - a fake or in-memory `withDb` for the Drizzle client (currently binds a
//     Cloudflare Hyperdrive/D1 pool that is not available in unit tests).
// Reintroduce these once a test-only Hono app + in-memory DB fixture land in
// apps/api/test/support.
describe.skip('POST /v1/trades/verify — route-level fixtures', () => {
  it('duplicate (chainId, txHash) insertion is idempotent via onConflictDoNothing', async () => {
    // Requires live/mocked withDb.
  });
  it('failed receipt (status 0x0) returns a structured 4xx', async () => {
    // Requires mocked fetch + a route wrapper that maps validator errors to
    // structured JSON.
  });
  it('sender mismatch on the RPC receipt is rejected', async () => {});
  it('unexpected destination (to !== ZEROX_SETTLER) is rejected', async () => {});
});
