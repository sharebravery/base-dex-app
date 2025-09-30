export type Bindings = {
  APP_ENV: 'mock' | 'staging' | 'production';
  MARKET_API_BASE_URL: string;
  MARKET_API_KEY?: string;
  /**
   * KyberSwap aggregator client id — a free public identifier (no key needed).
   * Sent as `x-client-id` on every call; stricter rate limits apply without it.
   * Defaults to `dex-demo` in mock/dev; override in wrangler for staging/prod.
   */
  KYBERSWAP_CLIENT_ID: string;
  /**
   * On-chain contract address the mobile client is allowed to send swap tx to.
   * Only used by `/v1/trades/verify` when the mobile client posts a real
   * receipt — not exercised in demo mode (we don't sign on-chain).
   * Set to the aggregator router address (KyberSwap: 0x6131B5fae19EA4f9D964eAc0408E4408b66337b5).
   */
  ALLOWED_SETTLER: string;
  /**
   * Comma-separated CORS allowlist for browser clients (e.g. Flutter web
   * builds served from a specific origin). Non-browser callers (Flutter
   * iOS/Android, curl, server-to-server) send no `Origin` header and bypass
   * this list. Empty in mock/dev; wildcarded suffixes (e.g. `https://*.pages.dev`)
   * are supported via a trailing `*`.
   */
  CORS_ORIGINS?: string;
  JWT_SECRET: string;
  SIWE_DOMAIN: string;
  SIWE_URI: string;
  BASE_RPC_URL: string;
  BASE_USDC_ADDRESS: string;
  HYPERDRIVE: Hyperdrive;
};
