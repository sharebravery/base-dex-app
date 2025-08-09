import {
  bigint,
  boolean,
  integer,
  jsonb,
  pgTable,
  primaryKey,
  text,
  timestamp,
  uniqueIndex,
  uuid,
} from 'drizzle-orm/pg-core';

export const profiles = pgTable('profiles', {
  id: uuid('id').defaultRandom().primaryKey(),
  walletAddress: text('wallet_address').notNull().unique(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
});

export const siweNonces = pgTable('siwe_nonces', {
  nonce: text('nonce').primaryKey(),
  walletAddress: text('wallet_address'),
  expiresAt: timestamp('expires_at', { withTimezone: true }).notNull(),
  consumedAt: timestamp('consumed_at', { withTimezone: true }),
});

export const userSettings = pgTable('user_settings', {
  profileId: uuid('profile_id').references(() => profiles.id).primaryKey(),
  locale: text('locale').notNull().default('en'),
  appearance: text('appearance').notNull().default('system'),
  displayCurrency: text('display_currency').notNull().default('USD'),
  preferBiometrics: boolean('prefer_biometrics').notNull().default(true),
});

export const watchlists = pgTable(
  'watchlists',
  {
    profileId: uuid('profile_id').references(() => profiles.id).notNull(),
    assetId: text('asset_id').notNull(),
    sortOrder: integer('sort_order').notNull().default(0),
  },
  (table) => [primaryKey({ columns: [table.profileId, table.assetId] })],
);

export const appTrades = pgTable(
  'app_trades',
  {
    id: uuid('id').defaultRandom().primaryKey(),
    profileId: uuid('profile_id').references(() => profiles.id).notNull(),
    chainId: integer('chain_id').notNull(),
    txHash: text('tx_hash').notNull(),
    sellToken: text('sell_token'),
    buyToken: text('buy_token'),
    sellAmount: bigint('sell_amount', { mode: 'bigint' }),
    buyAmount: bigint('buy_amount', { mode: 'bigint' }),
    metadata: jsonb('metadata').notNull().default({}),
    executedAt: timestamp('executed_at', { withTimezone: true }).notNull(),
  },
  (table) => [uniqueIndex('app_trades_chain_tx_unique').on(table.chainId, table.txHash)],
);
