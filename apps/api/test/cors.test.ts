import { describe, expect, it } from 'vitest';
import app from '../src/index';

const baseEnv = {
  APP_ENV: 'mock' as const,
  MARKET_API_BASE_URL: 'https://api.binance.com',
  KYBERSWAP_CLIENT_ID: 'dex-demo',
  ALLOWED_SETTLER: '0x0000000000000000000000000000000000000000',
};

describe('CORS allowlist', () => {
  it('allows localhost with any port in dev', async () => {
    const response = await app.request(
      '/health',
      { method: 'GET', headers: { origin: 'http://localhost:5000' } },
      { ...baseEnv, CORS_ORIGINS: '' },
    );
    expect(response.headers.get('access-control-allow-origin')).toBe(
      'http://localhost:5000',
    );
  });

  it('allows an env-listed exact origin', async () => {
    const response = await app.request(
      '/health',
      {
        method: 'GET',
        headers: { origin: 'https://demo.example.com' },
      },
      { ...baseEnv, CORS_ORIGINS: 'https://demo.example.com' },
    );
    expect(response.headers.get('access-control-allow-origin')).toBe(
      'https://demo.example.com',
    );
  });

  it('rejects an unknown origin', async () => {
    const response = await app.request(
      '/health',
      { method: 'GET', headers: { origin: 'https://evil.example.com' } },
      { ...baseEnv, CORS_ORIGINS: 'https://demo.example.com' },
    );
    expect(response.headers.get('access-control-allow-origin')).toBeNull();
  });

  it('supports trailing wildcard for Cloudflare Pages preview URLs', async () => {
    const response = await app.request(
      '/health',
      { method: 'GET', headers: { origin: 'https://feat-abc.dex.pages.dev' } },
      { ...baseEnv, CORS_ORIGINS: 'https://*.dex.pages.dev' },
    );
    expect(response.headers.get('access-control-allow-origin')).toBe(
      'https://feat-abc.dex.pages.dev',
    );
  });

  it('does not add dev defaults in production', async () => {
    const response = await app.request(
      '/health',
      { method: 'GET', headers: { origin: 'http://localhost:5000' } },
      {
        ...baseEnv,
        APP_ENV: 'production' as const,
        CORS_ORIGINS: 'https://prod.example.com',
      },
    );
    expect(response.headers.get('access-control-allow-origin')).toBeNull();
  });

  it('lets non-browser callers through (no Origin header)', async () => {
    const response = await app.request('/health', { method: 'GET' }, baseEnv);
    expect(response.status).toBe(200);
  });
});
