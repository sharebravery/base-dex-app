import { describe, expect, it } from 'vitest';
import { consumeNonce, createNonceStore } from '../src/auth/service';

describe('SIWE nonce lifecycle', () => {
  it('accepts a live nonce once and rejects replay', async () => {
    const store = createNonceStore();
    store.set('nonce-1', Date.now() + 300_000);
    expect(consumeNonce(store, 'nonce-1', Date.now())).toBe(true);
    expect(consumeNonce(store, 'nonce-1', Date.now())).toBe(false);
  });

  it('rejects an expired nonce', () => {
    const store = createNonceStore();
    store.set('nonce-2', Date.now() - 1);
    expect(consumeNonce(store, 'nonce-2', Date.now())).toBe(false);
  });
});
