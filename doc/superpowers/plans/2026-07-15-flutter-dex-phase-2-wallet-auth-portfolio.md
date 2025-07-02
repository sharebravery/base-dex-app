# Flutter DEX Phase 2 — Wallet, SIWE, and Portfolio Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Track each checkbox and review each task before continuing.

**Goal:** Add a recoverable embedded wallet behind a safe application interface, create SIWE-backed application sessions, connect the Worker to Supabase PostgreSQL through Drizzle/Hyperdrive, and render verified Base balances in Portfolio.

**Architecture:** Web3Auth remains isolated inside `Web3AuthWalletService`; controllers never receive raw key material. SIWE binds the application profile to the wallet address. The Worker owns nonce consumption, JWT issuance, database access, and authenticated profile reads.

**Tech Stack:** Web3Auth Flutter, web3dart, local_auth, flutter_secure_storage, Hono, SIWE, JOSE, Drizzle ORM, node-postgres, Hyperdrive, Supabase PostgreSQL.

## Global Constraints

- Apply every constraint from the master plan.
- Never add a `getPrivateKeyForSigning()` method to an application-facing interface.
- SDK key material may exist only inside `Web3AuthWalletService` for the duration of a signing call.
- SIWE nonce lifetime is five minutes and each nonce is consumed exactly once.
- App JWT lifetime is 24 hours; Version 1 has no refresh token.
- Flutter never connects directly to Supabase PostgreSQL.

---

## File Map

```text
apps/mobile/lib/features/auth/
├── auth_controller.dart
├── auth_models.dart
├── app_session_repository.dart
├── sign_in_screen.dart
├── wallet_service.dart
└── web3auth_wallet_service.dart
apps/mobile/lib/core/
├── secure_storage.dart
└── web3/{base_chain.dart,erc20_abi.dart,evm_rpc.dart}
apps/mobile/lib/features/portfolio/
├── portfolio_controller.dart
├── portfolio_models.dart
├── portfolio_repository.dart
└── portfolio_screen.dart
apps/api/src/
├── auth/{middleware.ts,routes.ts,service.ts}
├── db/{client.ts,schema.ts}
└── index.ts
```

---

### Task 5: Integrate Web3Auth Behind a Safe Wallet Service

**Files:**
- Create: `apps/mobile/lib/features/auth/auth_models.dart`
- Create: `apps/mobile/lib/features/auth/wallet_service.dart`
- Create: `apps/mobile/lib/features/auth/web3auth_wallet_service.dart`
- Create: `apps/mobile/lib/features/auth/auth_controller.dart`
- Create: `apps/mobile/lib/features/auth/auth_providers.dart`
- Create: `apps/mobile/lib/features/auth/sign_in_screen.dart`
- Modify: `apps/mobile/lib/app/router.dart`
- Modify: platform Web3Auth callback configuration
- Test: `apps/mobile/test/features/auth/auth_controller_test.dart`
- Test: `apps/mobile/test/features/auth/wallet_service_boundary_test.dart`

**Interfaces:**
- Consumes: `AppConfig` from Phase 1.
- Produces: `WalletLoginMethod`, `WalletSession`, `EvmTransactionRequest`, `WalletService`, `AuthController`.

- [ ] **Step 1: Write controller and boundary tests**

Create `apps/mobile/test/features/auth/auth_controller_test.dart`:

```dart
import 'package:dex_app/features/auth/auth_controller.dart';
import 'package:dex_app/features/auth/auth_models.dart';
import 'package:dex_app/features/auth/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';

final class FakeWalletService implements WalletService {
  WalletSession? restored;
  int logoutCalls = 0;

  @override
  Future<WalletSession?> restoreSession() async => restored;

  @override
  Future<WalletSession> login(WalletLoginMethod method) async =>
      const WalletSession(
        address: '0x1111111111111111111111111111111111111111',
        email: 'user@example.com',
        displayName: 'User',
      );

  @override
  Future<String> signMessage(String message) async => '0xsigned';

  @override
  Future<String> signTransaction(EvmTransactionRequest request) async =>
      '0xraw';

  @override
  Future<void> logout() async => logoutCalls++;
}

void main() {
  test('restores and logs in without exposing key material', () async {
    final service = FakeWalletService();
    final controller = AuthController(service);
    expect(await controller.restore(), isNull);

    final session = await controller.login(WalletLoginMethod.google);
    expect(session.address, startsWith('0x'));
    expect(controller.session, session);
  });
}
```

Create `apps/mobile/test/features/auth/wallet_service_boundary_test.dart`:

```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('application wallet interface never exposes private-key methods', () {
    final source = File('lib/features/auth/wallet_service.dart').readAsStringSync();
    expect(source, isNot(contains('getPrivateKey')));
    expect(source, isNot(contains('privKey')));
    expect(source, contains('signMessage'));
    expect(source, contains('signTransaction'));
  });
}
```

- [ ] **Step 2: Run tests and verify red state**

```bash
flutter test test/features/auth
```

Expected: missing auth files.

- [ ] **Step 3: Define application-facing wallet contracts**

Create `apps/mobile/lib/features/auth/auth_models.dart`:

```dart
enum WalletLoginMethod { email, apple, google }

final class WalletSession {
  const WalletSession({
    required this.address,
    required this.email,
    required this.displayName,
  });

  final String address;
  final String? email;
  final String? displayName;
}

final class EvmTransactionRequest {
  const EvmTransactionRequest({
    required this.to,
    required this.data,
    required this.value,
    required this.gasLimit,
    required this.maxFeePerGas,
    required this.maxPriorityFeePerGas,
    required this.nonce,
    required this.chainId,
  });

  final String to;
  final String data;
  final BigInt value;
  final BigInt gasLimit;
  final BigInt maxFeePerGas;
  final BigInt maxPriorityFeePerGas;
  final int nonce;
  final int chainId;
}
```

Create `apps/mobile/lib/features/auth/wallet_service.dart`:

```dart
import 'package:dex_app/features/auth/auth_models.dart';

abstract interface class WalletService {
  Future<WalletSession?> restoreSession();
  Future<WalletSession> login(WalletLoginMethod method);
  Future<String> signMessage(String message);
  Future<String> signTransaction(EvmTransactionRequest request);
  Future<void> logout();
}
```

Create `apps/mobile/lib/features/auth/auth_controller.dart`:

```dart
import 'package:dex_app/features/auth/auth_models.dart';
import 'package:dex_app/features/auth/wallet_service.dart';

final class AuthController {
  AuthController(this._walletService);
  final WalletService _walletService;

  WalletSession? _session;
  WalletSession? get session => _session;

  Future<WalletSession?> restore() async {
    _session = await _walletService.restoreSession();
    return _session;
  }

  Future<WalletSession> login(WalletLoginMethod method) async {
    _session = await _walletService.login(method);
    return _session!;
  }

  Future<void> logout() async {
    await _walletService.logout();
    _session = null;
  }
}
```

- [ ] **Step 4: Add SDK dependencies and implement isolated Web3Auth adapter**

```bash
cd apps/mobile
flutter pub add web3auth_flutter web3dart
```

Create `apps/mobile/lib/features/auth/web3auth_wallet_service.dart`:

```dart
import 'dart:typed_data';
import 'package:dex_app/features/auth/auth_models.dart';
import 'package:dex_app/features/auth/wallet_service.dart';
import 'package:convert/convert.dart';
import 'package:http/http.dart';
import 'package:web3auth_flutter/enums.dart';
import 'package:web3auth_flutter/input.dart';
import 'package:web3auth_flutter/web3auth_flutter.dart';
import 'package:web3dart/web3dart.dart';

final class Web3AuthWalletService implements WalletService {
  Web3AuthWalletService({
    required this.clientId,
    required this.redirectUrl,
  });

  final String clientId;
  final Uri redirectUrl;

  Future<void> initialize() async {
    await Web3AuthFlutter.init(
      Web3AuthOptions(
        clientId: clientId,
        network: Network.sapphire_mainnet,
        redirectUrl: redirectUrl,
      ),
    );
    await Web3AuthFlutter.initialize();
  }

  @override
  Future<WalletSession?> restoreSession() async {
    final key = await Web3AuthFlutter.getPrivKey();
    if (key.isEmpty) return null;
    final address = EthPrivateKey.fromHex(key).address.hexEip55;
    final user = await Web3AuthFlutter.getUserInfo();
    return WalletSession(
      address: address,
      email: user.email,
      displayName: user.name,
    );
  }

  @override
  Future<WalletSession> login(WalletLoginMethod method) async {
    final provider = switch (method) {
      WalletLoginMethod.email => Provider.email_passwordless,
      WalletLoginMethod.apple => Provider.apple,
      WalletLoginMethod.google => Provider.google,
    };
    final response = await Web3AuthFlutter.login(
      LoginParams(loginProvider: provider),
    );
    final key = response.privKey;
    if (key == null || key.isEmpty) {
      throw StateError('Web3Auth returned no signing key');
    }
    final address = EthPrivateKey.fromHex(key).address.hexEip55;
    return WalletSession(
      address: address,
      email: response.userInfo?.email,
      displayName: response.userInfo?.name,
    );
  }

  @override
  Future<String> signMessage(String message) async {
    final key = await Web3AuthFlutter.getPrivKey();
    if (key.isEmpty) throw StateError('Wallet session is not available');
    final credentials = EthPrivateKey.fromHex(key);
    final signature = await credentials.signPersonalMessage(
      Uint8List.fromList(message.codeUnits),
    );
    return '0x${hex.encode(signature)}';
  }

  @override
  Future<String> signTransaction(EvmTransactionRequest request) async {
    if (request.chainId != 8453) throw ArgumentError('Unexpected chain ID');
    final key = await Web3AuthFlutter.getPrivKey();
    if (key.isEmpty) throw StateError('Wallet session is not available');
    final credentials = EthPrivateKey.fromHex(key);
    final client = Web3Client('http://localhost', Client());
    try {
      final raw = await client.signTransaction(
        credentials,
        Transaction(
          to: EthereumAddress.fromHex(request.to),
          data: Uint8List.fromList(hex.decode(request.data.replaceFirst('0x', ''))),
          value: EtherAmount.inWei(request.value),
          maxGas: request.gasLimit.toInt(),
          maxFeePerGas: EtherAmount.inWei(request.maxFeePerGas),
          maxPriorityFeePerGas:
              EtherAmount.inWei(request.maxPriorityFeePerGas),
          nonce: request.nonce,
        ),
        chainId: request.chainId,
      );
      return '0x${hex.encode(raw)}';
    } finally {
      client.dispose();
    }
  }

  @override
  Future<void> logout() => Web3AuthFlutter.logout();
}
```

The SDK-specific file is the only application file permitted to call `getPrivKey()`.

- [ ] **Step 5: Add sign-in UI and auth redirect**

Create `apps/mobile/lib/features/auth/sign_in_screen.dart`:

```dart
import 'package:dex_app/features/auth/auth_models.dart';
import 'package:flutter/material.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({required this.onLogin, super.key});

  final Future<void> Function(WalletLoginMethod method) onLogin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Trade on-chain', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 12),
              const Text('Your embedded wallet is recoverable through your login.'),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => onLogin(WalletLoginMethod.apple),
                child: const Text('Continue with Apple'),
              ),
              FilledButton.tonal(
                onPressed: () => onLogin(WalletLoginMethod.google),
                child: const Text('Continue with Google'),
              ),
              TextButton(
                onPressed: () => onLogin(WalletLoginMethod.email),
                child: const Text('Continue with email'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

Create `apps/mobile/lib/features/auth/auth_providers.dart`:

```dart
import 'package:dex_app/features/auth/auth_controller.dart';
import 'package:dex_app/features/auth/auth_models.dart';
import 'package:dex_app/features/auth/wallet_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final walletServiceProvider = Provider<WalletService>((ref) {
  throw StateError('walletServiceProvider must be overridden at bootstrap');
});

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref.watch(walletServiceProvider));
});

final activeWalletSessionProvider = StateProvider<WalletSession?>((ref) => null);
```

Add this route to `app/router.dart` before the shell route:

```dart
GoRoute(
  path: '/sign-in',
  builder: (context, state) => Consumer(
    builder: (context, ref, child) => SignInScreen(
      onLogin: (method) async {
        final session = await ref.read(authControllerProvider).login(method);
        ref.read(activeWalletSessionProvider.notifier).state = session;
        if (context.mounted) context.go('/market');
      },
    ),
  ),
),
```

Add imports for `flutter_riverpod`, `auth_providers.dart`, and `sign_in_screen.dart`.

- [ ] **Step 6: Configure iOS and Android callbacks**

In `apps/mobile/ios/Podfile`, set:

```ruby
platform :ios, '14.0'
```

In `apps/mobile/ios/Runner/Info.plist`, add inside the root `<dict>`:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.cloudysky.dexapp</string>
    </array>
  </dict>
</array>
```

In `apps/mobile/android/app/build.gradle` or `build.gradle.kts`, set `minSdk` to `26`. In `AndroidManifest.xml`, add to `MainActivity`:

```xml
<intent-filter>
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="com.cloudysky.dexapp" android:host="auth" />
</intent-filter>
```

Use `com.cloudysky.dexapp://auth` as the adapter redirect URL in all environments; only the Web3Auth client ID changes through `--dart-define`.

- [ ] **Step 7: Verify and commit**

```bash
flutter analyze
flutter test test/features/auth

git add apps/mobile
git commit -m "feat: isolate recoverable embedded wallet"
```

---

### Task 6: Add SIWE, Drizzle, Hyperdrive, and Supabase PostgreSQL

**Files:**
- Create: `apps/api/src/db/schema.ts`
- Create: `apps/api/src/db/client.ts`
- Create: `apps/api/drizzle.config.ts`
- Create: `apps/api/src/auth/service.ts`
- Create: `apps/api/src/auth/routes.ts`
- Create: `apps/api/src/auth/middleware.ts`
- Modify: `apps/api/src/env.ts`
- Modify: `apps/api/src/index.ts`
- Modify: `apps/api/wrangler.jsonc`
- Create: `apps/api/test/auth.test.ts`
- Create: `apps/mobile/lib/core/secure_storage.dart`
- Create: `apps/mobile/lib/features/auth/app_session_repository.dart`
- Test: `apps/mobile/test/features/auth/app_session_repository_test.dart`

**Interfaces:**
- Consumes: `WalletService.signMessage()` and `WalletSession.address` from Task 5.
- Produces: `POST /v1/auth/challenge`, `POST /v1/auth/verify`, `requireAppSession`, `AppSessionRepository.signIn()`.

- [ ] **Step 1: Write SIWE nonce and replay tests**

Create `apps/api/test/auth.test.ts`:

```ts
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
```

- [ ] **Step 2: Run tests and verify red state**

```bash
cd apps/api
npm test -- auth.test.ts
```

Expected: missing auth service.

- [ ] **Step 3: Install database and auth dependencies**

```bash
cd apps/api
npm config set save-exact true
npm install drizzle-orm pg siwe jose
npm install --save-dev drizzle-kit @types/pg
```

- [ ] **Step 4: Define Drizzle schema and Hyperdrive client**

Create `apps/api/src/db/schema.ts`:

```ts
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
```

Extend `apps/api/src/env.ts`:

```ts
export type Bindings = {
  APP_ENV: 'mock' | 'staging' | 'production';
  MARKET_API_BASE_URL: string;
  MARKET_API_KEY?: string;
  JWT_SECRET: string;
  SIWE_DOMAIN: string;
  SIWE_URI: string;
  HYPERDRIVE: Hyperdrive;
};
```

Create `apps/api/src/db/client.ts`:

```ts
import { drizzle } from 'drizzle-orm/node-postgres';
import { Client } from 'pg';
import type { Bindings } from '../env';
import * as schema from './schema';

export async function withDb<T>(
  env: Bindings,
  operation: (db: ReturnType<typeof drizzle<typeof schema>>) => Promise<T>,
): Promise<T> {
  const client = new Client({ connectionString: env.HYPERDRIVE.connectionString });
  await client.connect();
  try {
    return await operation(drizzle(client, { schema }));
  } finally {
    await client.end();
  }
}
```

Create `apps/api/drizzle.config.ts`:

```ts
import { defineConfig } from 'drizzle-kit';

export default defineConfig({
  schema: './src/db/schema.ts',
  out: './drizzle',
  dialect: 'postgresql',
  dbCredentials: { url: process.env.DATABASE_URL ?? '' },
});
```

- [ ] **Step 5: Implement SIWE challenge, verification, and JWT middleware**

Create `apps/api/src/auth/service.ts`:

```ts
import { SignJWT, jwtVerify } from 'jose';
import { generateNonce, SiweMessage } from 'siwe';

export type NonceStore = Map<string, number>;
export const createNonceStore = (): NonceStore => new Map();

export function consumeNonce(store: NonceStore, nonce: string, now: number) {
  const expiresAt = store.get(nonce);
  if (expiresAt == null || expiresAt < now) return false;
  store.delete(nonce);
  return true;
}

export function createChallenge() {
  return { nonce: generateNonce(), expiresAt: new Date(Date.now() + 300_000) };
}

const secret = (value: string) => new TextEncoder().encode(value);

export async function issueJwt(walletAddress: string, jwtSecret: string) {
  return new SignJWT({ walletAddress })
    .setProtectedHeader({ alg: 'HS256' })
    .setSubject(walletAddress.toLowerCase())
    .setIssuedAt()
    .setExpirationTime('24h')
    .sign(secret(jwtSecret));
}

export async function verifyJwt(token: string, jwtSecret: string) {
  return jwtVerify(token, secret(jwtSecret));
}

export async function verifySiwe(input: {
  message: string;
  signature: string;
  nonce: string;
  domain: string;
  uri: string;
}) {
  const message = new SiweMessage(input.message);
  const result = await message.verify({
    signature: input.signature,
    nonce: input.nonce,
    domain: input.domain,
  });
  if (result.data.uri !== input.uri || result.data.chainId !== 8453) {
    throw new Error('invalid_siwe_scope');
  }
  return result.data;
}
```

Create `apps/api/src/auth/middleware.ts`:

```ts
import { createMiddleware } from 'hono/factory';
import type { Bindings } from '../env';
import { verifyJwt } from './service';

export type AuthVariables = { walletAddress: string };

export const requireAppSession = createMiddleware<{
  Bindings: Bindings;
  Variables: AuthVariables;
}>(async (context, next) => {
  const authorization = context.req.header('authorization');
  if (!authorization?.startsWith('Bearer ')) {
    return context.json({ error: 'unauthorized' }, 401);
  }
  try {
    const { payload } = await verifyJwt(
      authorization.slice('Bearer '.length),
      context.env.JWT_SECRET,
    );
    const walletAddress = payload.walletAddress;
    if (typeof walletAddress !== 'string') throw new Error('missing_wallet');
    context.set('walletAddress', walletAddress.toLowerCase());
    await next();
  } catch {
    return context.json({ error: 'unauthorized' }, 401);
  }
});
```

Create `apps/api/src/auth/routes.ts`:

```ts
import { eq, isNull } from 'drizzle-orm';
import { Hono } from 'hono';
import { z } from 'zod';
import type { Bindings } from '../env';
import { withDb } from '../db/client';
import { profiles, siweNonces, userSettings } from '../db/schema';
import { createChallenge, issueJwt, verifySiwe } from './service';

export const authRoutes = new Hono<{ Bindings: Bindings }>();

const verifySchema = z.object({ message: z.string(), signature: z.string() });

authRoutes.post('/auth/challenge', async (context) => {
  const challenge = createChallenge();
  await withDb(context.env, (db) =>
    db.insert(siweNonces).values({
      nonce: challenge.nonce,
      expiresAt: challenge.expiresAt,
    }),
  );
  return context.json({
    nonce: challenge.nonce,
    expiresAt: challenge.expiresAt.toISOString(),
    domain: context.env.SIWE_DOMAIN,
    uri: context.env.SIWE_URI,
    chainId: 8453,
  });
});

authRoutes.post('/auth/verify', async (context) => {
  const body = verifySchema.parse(await context.req.json());
  const messageNonce = body.message.match(/Nonce: ([A-Za-z0-9]+)/)?.[1];
  if (!messageNonce) return context.json({ error: 'invalid_nonce' }, 400);

  const nonce = await withDb(context.env, async (db) => {
    const rows = await db
      .select()
      .from(siweNonces)
      .where(eq(siweNonces.nonce, messageNonce))
      .limit(1);
    const row = rows[0];
    if (!row || row.consumedAt || row.expiresAt < new Date()) return null;
    await db
      .update(siweNonces)
      .set({ consumedAt: new Date() })
      .where(eq(siweNonces.nonce, messageNonce));
    return row;
  });
  if (!nonce) return context.json({ error: 'invalid_nonce' }, 400);

  const verified = await verifySiwe({
    message: body.message,
    signature: body.signature,
    nonce: messageNonce,
    domain: context.env.SIWE_DOMAIN,
    uri: context.env.SIWE_URI,
  });
  const walletAddress = verified.address.toLowerCase();

  await withDb(context.env, async (db) => {
    const inserted = await db
      .insert(profiles)
      .values({ walletAddress })
      .onConflictDoNothing()
      .returning({ id: profiles.id });
    const profile = inserted[0] ?? (
      await db.select({ id: profiles.id }).from(profiles)
        .where(eq(profiles.walletAddress, walletAddress)).limit(1)
    )[0];
    await db.insert(userSettings).values({ profileId: profile.id })
      .onConflictDoNothing();
  });

  return context.json({
    token: await issueJwt(walletAddress, context.env.JWT_SECRET),
    expiresInSeconds: 86400,
    walletAddress,
  });
});
```

Mount `authRoutes` in `src/index.ts` with `app.route('/v1', authRoutes)`.

- [ ] **Step 6: Configure Hyperdrive binding and migration scripts**

Create the staging Hyperdrive configuration and inject its returned ID into `wrangler.jsonc` without a hand-written placeholder:

```bash
cd apps/api
: "${DATABASE_URL:?Set DATABASE_URL to the restricted Supabase direct PostgreSQL connection string}"
HYPERDRIVE_ID=$(npx wrangler hyperdrive create dex-db \
  --connection-string="$DATABASE_URL" --json | \
  node -e "let s='';process.stdin.on('data',d=>s+=d).on('end',()=>process.stdout.write(JSON.parse(s).id))")
node - <<'NODE'
const fs = require('node:fs');
const path = 'wrangler.jsonc';
const id = process.env.HYPERDRIVE_ID;
if (!id) throw new Error('HYPERDRIVE_ID is empty');
const raw = fs.readFileSync(path, 'utf8');
const parsed = JSON.parse(raw.replace(/^\s*\/\/.*$/gm, ''));
parsed.hyperdrive = [{ binding: 'HYPERDRIVE', id }];
fs.writeFileSync(path, JSON.stringify(parsed, null, 2) + '\n');
NODE
```

Use the restricted `dex_app` database role and Supabase direct PostgreSQL host. Never commit `DATABASE_URL`.

Add scripts to `package.json`:

```json
{
  "scripts": {
    "db:generate": "drizzle-kit generate",
    "db:migrate": "drizzle-kit migrate"
  }
}
```

Before deployment, replace the documented Hyperdrive ID with the staging binding created for the restricted Supabase database role. The plan intentionally keeps the environment-specific identifier outside source code review.

- [ ] **Step 7: Implement Flutter SIWE repository and secure JWT storage**

Create `apps/mobile/lib/core/secure_storage.dart`:

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final class SecureStorage {
  SecureStorage(this._storage);
  final FlutterSecureStorage _storage;

  static const _jwtKey = 'app_session_jwt';

  Future<void> writeJwt(String token) => _storage.write(key: _jwtKey, value: token);
  Future<String?> readJwt() => _storage.read(key: _jwtKey);
  Future<void> clearJwt() => _storage.delete(key: _jwtKey);
}
```

Add dependencies:

```bash
flutter pub add flutter_secure_storage siwe
```

Create `apps/mobile/lib/features/auth/app_session_repository.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:dex_app/core/secure_storage.dart';
import 'package:dex_app/features/auth/auth_models.dart';
import 'package:dex_app/features/auth/wallet_service.dart';
import 'package:siwe/siwe.dart';

final class AppSession {
  const AppSession({required this.token, required this.walletAddress});
  final String token;
  final String walletAddress;
}

final class AppSessionRepository {
  AppSessionRepository(this._dio, this._wallet, this._storage);
  final Dio _dio;
  final WalletService _wallet;
  final SecureStorage _storage;

  Future<AppSession> signIn(WalletSession walletSession) async {
    final challenge = await _dio.post<Map<String, Object?>>('/v1/auth/challenge');
    final data = challenge.data!;
    final message = SiweMessage(
      domain: data['domain']! as String,
      address: walletSession.address,
      statement: 'Sign in to Flutter DEX',
      uri: data['uri']! as String,
      version: '1',
      chainId: data['chainId']! as int,
      nonce: data['nonce']! as String,
      issuedAt: DateTime.now().toUtc().toIso8601String(),
      expirationTime: data['expiresAt']! as String,
    ).prepareMessage();
    final signature = await _wallet.signMessage(message);
    final verified = await _dio.post<Map<String, Object?>>(
      '/v1/auth/verify',
      data: {'message': message, 'signature': signature},
    );
    final token = verified.data!['token']! as String;
    await _storage.writeJwt(token);
    return AppSession(token: token, walletAddress: walletSession.address);
  }
}
```

- [ ] **Step 8: Verify and commit**

```bash
cd apps/api
npm run db:generate
npm run typecheck
npm test
cd ../mobile
flutter analyze
flutter test test/features/auth

git add apps
git commit -m "feat: add SIWE application sessions"
```

---

### Task 7: Load Base Balances and Build Portfolio

**Files:**
- Create: `apps/mobile/lib/core/web3/base_chain.dart`
- Create: `apps/mobile/lib/core/web3/erc20_abi.dart`
- Create: `apps/mobile/lib/core/web3/evm_rpc.dart`
- Create: `apps/mobile/lib/features/portfolio/portfolio_models.dart`
- Create: `apps/mobile/lib/features/portfolio/portfolio_repository.dart`
- Create: `apps/mobile/lib/features/portfolio/portfolio_controller.dart`
- Create: `apps/mobile/lib/features/portfolio/portfolio_providers.dart`
- Create: `apps/mobile/lib/features/portfolio/portfolio_screen.dart`
- Modify: `apps/mobile/lib/app/router.dart`
- Test: `apps/mobile/test/features/portfolio/portfolio_repository_test.dart`
- Test: `apps/mobile/test/features/portfolio/portfolio_controller_test.dart`

**Interfaces:**
- Consumes: `WalletSession.address`, `BaseTokens`, and current ETH price from `MarketRepository`.
- Produces: `EvmRpc`, `Holding`, `PortfolioSnapshot`, `PortfolioRepository.load()`.

- [ ] **Step 1: Write portfolio value tests**

Create `apps/mobile/test/features/portfolio/portfolio_controller_test.dart`:

```dart
import 'package:decimal/decimal.dart';
import 'package:dex_app/features/portfolio/portfolio_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calculates total value from exact decimal holdings', () {
    final snapshot = PortfolioSnapshot.fromHoldings([
      Holding(symbol: 'ETH', rawBalance: BigInt.parse('250000000000000000'), decimals: 18, priceUsd: Decimal.parse('3200')),
      Holding(symbol: 'USDC', rawBalance: BigInt.parse('500000000'), decimals: 6, priceUsd: Decimal.one),
    ]);
    expect(snapshot.totalValueUsd.toString(), '1300');
  });
}
```

- [ ] **Step 2: Run test and verify red state**

```bash
flutter test test/features/portfolio
```

Expected: missing portfolio models.

- [ ] **Step 3: Implement Base RPC boundary and models**

Create `apps/mobile/lib/core/web3/base_chain.dart`:

```dart
abstract final class BaseChain {
  static const chainId = 8453;
  static const usdcAddress = '0x833589fCD6eDb6E08f4c7C32D4f71b54bDa02913';
}
```

Create `apps/mobile/lib/core/web3/erc20_abi.dart`:

```dart
const erc20BalanceAbi = '''[
  {"type":"function","name":"balanceOf","stateMutability":"view","inputs":[{"name":"account","type":"address"}],"outputs":[{"name":"","type":"uint256"}]},
  {"type":"function","name":"allowance","stateMutability":"view","inputs":[{"name":"owner","type":"address"},{"name":"spender","type":"address"}],"outputs":[{"name":"","type":"uint256"}]}
]''';
```

Create `apps/mobile/lib/core/web3/evm_rpc.dart`:

```dart
import 'package:dex_app/core/web3/erc20_abi.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';

final class EvmRpc {
  EvmRpc(Uri rpcUrl) : _client = Web3Client(rpcUrl.toString(), Client());
  final Web3Client _client;

  Future<BigInt> nativeBalance(String address) async {
    final amount = await _client.getBalance(EthereumAddress.fromHex(address));
    return amount.getInWei;
  }

  Future<BigInt> erc20Balance(String token, String address) async {
    final contract = DeployedContract(
      ContractAbi.fromJson(erc20BalanceAbi, 'ERC20'),
      EthereumAddress.fromHex(token),
    );
    final result = await _client.call(
      contract: contract,
      function: contract.function('balanceOf'),
      params: [EthereumAddress.fromHex(address)],
    );
    return result.single as BigInt;
  }

  void dispose() => _client.dispose();
}
```

Create `apps/mobile/lib/features/portfolio/portfolio_models.dart`:

```dart
import 'package:decimal/decimal.dart';

final class Holding {
  const Holding({
    required this.symbol,
    required this.rawBalance,
    required this.decimals,
    required this.priceUsd,
  });

  final String symbol;
  final BigInt rawBalance;
  final int decimals;
  final Decimal priceUsd;

  Decimal get amount =>
      Decimal.parse(rawBalance.toString()) / Decimal.fromInt(BigInt.from(10).pow(decimals).toInt());
  Decimal get valueUsd => amount * priceUsd;
}

final class PortfolioSnapshot {
  const PortfolioSnapshot({required this.holdings, required this.totalValueUsd});

  factory PortfolioSnapshot.fromHoldings(List<Holding> holdings) {
    final total = holdings.fold(Decimal.zero, (sum, item) => sum + item.valueUsd);
    return PortfolioSnapshot(holdings: List.unmodifiable(holdings), totalValueUsd: total);
  }

  final List<Holding> holdings;
  final Decimal totalValueUsd;
}
```

- [ ] **Step 4: Implement repository and controller**

Create `apps/mobile/lib/features/portfolio/portfolio_repository.dart`:

```dart
import 'package:decimal/decimal.dart';
import 'package:dex_app/core/web3/base_chain.dart';
import 'package:dex_app/core/web3/evm_rpc.dart';
import 'package:dex_app/features/portfolio/portfolio_models.dart';

abstract interface class PortfolioRepository {
  Future<PortfolioSnapshot> load({
    required String address,
    required Decimal ethPriceUsd,
  });
}

final class RpcPortfolioRepository implements PortfolioRepository {
  RpcPortfolioRepository(this._rpc);
  final EvmRpc _rpc;

  @override
  Future<PortfolioSnapshot> load({required String address, required Decimal ethPriceUsd}) async {
    final results = await Future.wait([
      _rpc.nativeBalance(address),
      _rpc.erc20Balance(BaseChain.usdcAddress, address),
    ]);
    return PortfolioSnapshot.fromHoldings([
      Holding(symbol: 'ETH', rawBalance: results[0], decimals: 18, priceUsd: ethPriceUsd),
      Holding(symbol: 'USDC', rawBalance: results[1], decimals: 6, priceUsd: Decimal.one),
    ]);
  }
}
```

Create `apps/mobile/lib/features/portfolio/portfolio_controller.dart`:

```dart
import 'package:decimal/decimal.dart';
import 'package:dex_app/features/portfolio/portfolio_models.dart';
import 'package:dex_app/features/portfolio/portfolio_repository.dart';

final class PortfolioController {
  PortfolioController(this._repository);
  final PortfolioRepository _repository;

  Future<PortfolioSnapshot> load(String address, Decimal ethPriceUsd) =>
      _repository.load(address: address, ethPriceUsd: ethPriceUsd);
}
```

- [ ] **Step 5: Build Portfolio screen and route**

Create `apps/mobile/lib/features/portfolio/portfolio_screen.dart`:

```dart
import 'package:dex_app/features/portfolio/portfolio_models.dart';
import 'package:flutter/material.dart';

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({required this.snapshot, super.key});
  final PortfolioSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Portfolio')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('\$${snapshot.totalValueUsd}', style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 24),
            for (final holding in snapshot.holdings)
              ListTile(
                title: Text(holding.symbol),
                subtitle: Text(holding.amount.toString()),
                trailing: Text('\$${holding.valueUsd}'),
              ),
          ],
        ),
      ),
    );
  }
}
```

Create `apps/mobile/lib/features/portfolio/portfolio_providers.dart`:

```dart
import 'package:decimal/decimal.dart';
import 'package:dex_app/features/portfolio/portfolio_controller.dart';
import 'package:dex_app/features/portfolio/portfolio_models.dart';
import 'package:dex_app/features/portfolio/portfolio_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final portfolioRepositoryProvider = Provider<PortfolioRepository>((ref) {
  throw StateError('portfolioRepositoryProvider must be overridden at bootstrap');
});

final portfolioControllerProvider = Provider<PortfolioController>((ref) {
  return PortfolioController(ref.watch(portfolioRepositoryProvider));
});

final ethPriceUsdProvider = Provider<Decimal>((ref) {
  throw StateError('ethPriceUsdProvider must be overridden by Market state');
});

final portfolioSnapshotProvider = FutureProvider.family<
    PortfolioSnapshot, String>((ref, address) {
  return ref.watch(portfolioControllerProvider).load(
        address,
        ref.watch(ethPriceUsdProvider),
      );
});
```

Append this route wrapper to `portfolio_screen.dart`:

```dart
class PortfolioRouteScreen extends ConsumerWidget {
  const PortfolioRouteScreen({required this.address, super.key});
  final String address;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(portfolioSnapshotProvider(address)).when(
          data: (snapshot) => PortfolioScreen(snapshot: snapshot),
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => Scaffold(
            body: Center(child: Text(error.toString())),
          ),
        );
  }
}
```

Add imports for `flutter_riverpod` and `portfolio_providers.dart`. In `app/router.dart`, replace the `/portfolio` placeholder builder with:

```dart
builder: (context, state) => Consumer(
  builder: (context, ref, child) {
    final session = ref.watch(activeWalletSessionProvider);
    if (session == null) return const SignInScreen(onLogin: _unsupportedLogin);
    return PortfolioRouteScreen(address: session.address);
  },
),
```

Define `_unsupportedLogin` at file scope only to keep this branch compilable before the full router redirect is added:

```dart
Future<void> _unsupportedLogin(WalletLoginMethod method) async {
  throw StateError('Navigate to /sign-in to authenticate');
}
```

At bootstrap, override `portfolioRepositoryProvider` with a deterministic fake repository in `mock` and `RpcPortfolioRepository` in staging/production. Override `ethPriceUsdProvider` with the current ETH price from Market state. The Widget never calls RPC directly.

- [ ] **Step 6: Verify and commit**

```bash
flutter analyze
flutter test test/features/portfolio test/features/auth

git add apps/mobile
git commit -m "feat: add Base portfolio balances"
```

---

## Phase 2 Checkpoint

```bash
cd apps/mobile
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
cd ../api
npm ci
npm run db:generate
npm run typecheck
npm test
```

Expected: all commands pass. Manually verify the Web3Auth callback configuration on one iOS and one Android device before Phase 3.
