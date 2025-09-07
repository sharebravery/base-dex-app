export type Bindings = {
  APP_ENV: 'mock' | 'staging' | 'production';
  MARKET_API_BASE_URL: string;
  MARKET_API_KEY?: string;
  ZEROX_API_BASE_URL: string;
  ZEROX_API_KEY: string;
  ZEROX_ALLOWANCE_HOLDER: string;
  ZEROX_SETTLER: string;
  JWT_SECRET: string;
  SIWE_DOMAIN: string;
  SIWE_URI: string;
  BASE_RPC_URL: string;
  BASE_USDC_ADDRESS: string;
  HYPERDRIVE: Hyperdrive;
};
