export type Bindings = {
  APP_ENV: 'mock' | 'staging' | 'production';
  MARKET_API_BASE_URL: string;
  MARKET_API_KEY?: string;
  JWT_SECRET: string;
  SIWE_DOMAIN: string;
  SIWE_URI: string;
  HYPERDRIVE: Hyperdrive;
};
