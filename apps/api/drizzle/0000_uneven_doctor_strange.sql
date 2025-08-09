CREATE TABLE "app_trades" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"profile_id" uuid NOT NULL,
	"chain_id" integer NOT NULL,
	"tx_hash" text NOT NULL,
	"sell_token" text,
	"buy_token" text,
	"sell_amount" bigint,
	"buy_amount" bigint,
	"metadata" jsonb DEFAULT '{}'::jsonb NOT NULL,
	"executed_at" timestamp with time zone NOT NULL
);
--> statement-breakpoint
CREATE TABLE "profiles" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"wallet_address" text NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "profiles_wallet_address_unique" UNIQUE("wallet_address")
);
--> statement-breakpoint
CREATE TABLE "siwe_nonces" (
	"nonce" text PRIMARY KEY NOT NULL,
	"wallet_address" text,
	"expires_at" timestamp with time zone NOT NULL,
	"consumed_at" timestamp with time zone
);
--> statement-breakpoint
CREATE TABLE "user_settings" (
	"profile_id" uuid PRIMARY KEY NOT NULL,
	"locale" text DEFAULT 'en' NOT NULL,
	"appearance" text DEFAULT 'system' NOT NULL,
	"display_currency" text DEFAULT 'USD' NOT NULL,
	"prefer_biometrics" boolean DEFAULT true NOT NULL
);
--> statement-breakpoint
CREATE TABLE "watchlists" (
	"profile_id" uuid NOT NULL,
	"asset_id" text NOT NULL,
	"sort_order" integer DEFAULT 0 NOT NULL,
	CONSTRAINT "watchlists_profile_id_asset_id_pk" PRIMARY KEY("profile_id","asset_id")
);
--> statement-breakpoint
ALTER TABLE "app_trades" ADD CONSTRAINT "app_trades_profile_id_profiles_id_fk" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "user_settings" ADD CONSTRAINT "user_settings_profile_id_profiles_id_fk" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "watchlists" ADD CONSTRAINT "watchlists_profile_id_profiles_id_fk" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
CREATE UNIQUE INDEX "app_trades_chain_tx_unique" ON "app_trades" USING btree ("chain_id","tx_hash");