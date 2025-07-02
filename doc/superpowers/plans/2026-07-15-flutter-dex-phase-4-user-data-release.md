# Flutter DEX Phase 4 — User Data, Funding, and Release Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Track each checkbox and review each task before continuing.

**Goal:** Complete authenticated user data, backend-verified trade history, Deposit/Withdraw/Activity flows, bounded visual regression coverage, integration tests, security documentation, and the portfolio demo.

**Architecture:** Authenticated profile endpoints use the SIWE JWT middleware. Watchlist and settings are PostgreSQL-backed. Trade records are created only after Base receipt and log verification. Deposit is address presentation; Withdraw reuses the same biometric, signing, pending-store, and timeline infrastructure as Swap.

**Tech Stack:** Hono, Drizzle, Base JSON-RPC, Flutter, Riverpod, QR rendering, local_auth, golden tests, integration_test.

## Global Constraints

- Apply every constraint from the master plan.
- No direct Flutter-to-Supabase access.
- Do not record client-asserted trade amounts without receipt/log verification.
- Withdraw supports ETH and USDC only.
- Device authentication remains mandatory for Withdraw.
- Activity records display chain-derived status and Base explorer links.
- Keep the golden matrix near 20 images, not a Cartesian product.

---

### Task 11: Add Watchlist, Settings, and Verified Trade Storage

**Files:**
- Create: `apps/api/src/profile/routes.ts`
- Create: `apps/api/src/trades/verifier.ts`
- Create: `apps/api/src/trades/routes.ts`
- Modify: `apps/api/src/index.ts`
- Create: `apps/api/test/profile.test.ts`
- Create: `apps/api/test/trades.test.ts`
- Create: `apps/mobile/lib/features/settings/settings_models.dart`
- Create: `apps/mobile/lib/features/settings/settings_repository.dart`
- Create: `apps/mobile/lib/features/settings/settings_controller.dart`
- Create: `apps/mobile/lib/features/settings/settings_screen.dart`
- Modify: Market controller for watchlist sync
- Test: `apps/mobile/test/features/settings/settings_controller_test.dart`

**Interfaces:**
- Consumes: `requireAppSession`, Drizzle tables, active app JWT, market asset IDs.
- Produces: authenticated profile/settings/watchlist routes, `POST /v1/trades/verify`, `GET /v1/trades`, `SettingsRepository`.

- [ ] **Step 1: Write profile and verified-trade tests**

Create `apps/api/test/profile.test.ts`:

```ts
import { describe, expect, it } from 'vitest';
import { settingsSchema, watchlistSchema } from '../src/profile/routes';

describe('profile input schemas', () => {
  it('rejects unsupported locale values', () => {
    expect(() => settingsSchema.parse({
      locale: 'fr',
      appearance: 'system',
      displayCurrency: 'USD',
      preferBiometrics: true,
    })).toThrow();
  });

  it('accepts Simplified Chinese settings', () => {
    expect(settingsSchema.parse({
      locale: 'zh',
      appearance: 'dark',
      displayCurrency: 'USD',
      preferBiometrics: true,
    }).locale).toBe('zh');
  });

  it('rejects non-catalog watchlist assets', () => {
    expect(() => watchlistSchema.parse({ assetIds: ['unknown-token'] })).toThrow();
  });
});
```

Create `apps/api/test/trades.test.ts`:

```ts
import { describe, expect, it } from 'vitest';
import { validateVerifiedTrade } from '../src/trades/verifier';

describe('verified trade facts', () => {
  it('rejects a failed receipt', () => {
    expect(() => validateVerifiedTrade({
      chainId: 8453,
      status: 0,
      from: '0x1111111111111111111111111111111111111111',
      to: '0x0000000000000000000000000000000000000002',
      authenticatedWallet: '0x1111111111111111111111111111111111111111',
      allowedSettler: '0x0000000000000000000000000000000000000002',
      transfers: [],
    })).toThrow('failed_receipt');
  });

  it('rejects a sender mismatch', () => {
    expect(() => validateVerifiedTrade({
      chainId: 8453,
      status: 1,
      from: '0x2222222222222222222222222222222222222222',
      to: '0x0000000000000000000000000000000000000002',
      authenticatedWallet: '0x1111111111111111111111111111111111111111',
      allowedSettler: '0x0000000000000000000000000000000000000002',
      transfers: [],
    })).toThrow('sender_mismatch');
  });
});
```

- [ ] **Step 2: Run tests and verify red state**

```bash
cd apps/api
npm test -- profile.test.ts trades.test.ts
```

Expected: missing profile/trade modules.

- [ ] **Step 3: Implement authenticated profile, settings, and watchlist routes**

Create `apps/api/src/profile/routes.ts`:

```ts
import { and, eq } from 'drizzle-orm';
import { Hono } from 'hono';
import { z } from 'zod';
import type { Bindings } from '../env';
import { withDb } from '../db/client';
import { profiles, userSettings, watchlists } from '../db/schema';
import { requireAppSession, type AuthVariables } from '../auth/middleware';

export const profileRoutes = new Hono<{
  Bindings: Bindings;
  Variables: AuthVariables;
}>();
profileRoutes.use('*', requireAppSession);

async function profileForWallet(env: Bindings, walletAddress: string) {
  return withDb(env, async (db) => {
    const rows = await db.select().from(profiles)
      .where(eq(profiles.walletAddress, walletAddress)).limit(1);
    if (!rows[0]) throw new Error('profile_not_found');
    return rows[0];
  });
}

profileRoutes.get('/profile', async (context) => {
  const walletAddress = context.get('walletAddress');
  const profile = await profileForWallet(context.env, walletAddress);
  const settings = await withDb(context.env, (db) => db.select().from(userSettings)
    .where(eq(userSettings.profileId, profile.id)).limit(1));
  return context.json({ walletAddress, settings: settings[0] });
});

export const settingsSchema = z.object({
  locale: z.enum(['en', 'zh']),
  appearance: z.enum(['system', 'light', 'dark']),
  displayCurrency: z.literal('USD'),
  preferBiometrics: z.boolean(),
});

profileRoutes.put('/settings', async (context) => {
  const body = settingsSchema.parse(await context.req.json());
  const profile = await profileForWallet(context.env, context.get('walletAddress'));
  await withDb(context.env, (db) => db.update(userSettings).set(body)
    .where(eq(userSettings.profileId, profile.id)));
  return context.json(body);
});

profileRoutes.get('/watchlist', async (context) => {
  const profile = await profileForWallet(context.env, context.get('walletAddress'));
  const rows = await withDb(context.env, (db) => db.select().from(watchlists)
    .where(eq(watchlists.profileId, profile.id)));
  return context.json({ assetIds: rows.sort((a, b) => a.sortOrder - b.sortOrder).map((row) => row.assetId) });
});

export const watchlistSchema = z.object({
  assetIds: z.array(z.enum(['ethereum', 'bitcoin', 'solana', 'usd-coin', 'aerodrome-finance', 'degen-base'])).max(10),
});

profileRoutes.put('/watchlist', async (context) => {
  const body = watchlistSchema.parse(await context.req.json());
  const profile = await profileForWallet(context.env, context.get('walletAddress'));
  await withDb(context.env, async (db) => {
    await db.delete(watchlists).where(eq(watchlists.profileId, profile.id));
    if (body.assetIds.length > 0) {
      await db.insert(watchlists).values(body.assetIds.map((assetId, index) => ({
        profileId: profile.id,
        assetId,
        sortOrder: index,
      })));
    }
  });
  return context.json(body);
});
```

Mount `profileRoutes` with `app.route('/v1', profileRoutes)`.

- [ ] **Step 4: Implement receipt verification before trade insertion**

Create `apps/api/src/trades/verifier.ts`:

```ts
export type RpcLog = {
  address: string;
  topics: string[];
  data: string;
};

export type VerifiedDirection = {
  side: 'buy_eth' | 'sell_eth';
  usdcAmount: bigint;
};

const transferTopic =
  '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef';

function indexedAddress(topic: string) {
  return `0x${topic.slice(-40)}`.toLowerCase();
}

export function decodeUsdcDirection(input: {
  logs: RpcLog[];
  walletAddress: string;
  usdcAddress: string;
}): VerifiedDirection {
  const wallet = input.walletAddress.toLowerCase();
  const usdc = input.usdcAddress.toLowerCase();

  for (const log of input.logs) {
    if (log.address.toLowerCase() !== usdc) continue;
    if (log.topics[0]?.toLowerCase() !== transferTopic) continue;
    if (log.topics.length < 3) continue;

    const from = indexedAddress(log.topics[1]);
    const to = indexedAddress(log.topics[2]);
    const amount = BigInt(log.data);

    if (from === wallet && amount > 0n) {
      return { side: 'buy_eth', usdcAmount: amount };
    }
    if (to === wallet && amount > 0n) {
      return { side: 'sell_eth', usdcAmount: amount };
    }
  }

  throw new Error('missing_usdc_transfer');
}

export function validateVerifiedTrade(input: {
  chainId: number;
  status: number;
  from: string;
  to: string;
  authenticatedWallet: string;
  allowedSettler: string;
}) {
  if (input.chainId !== 8453) throw new Error('wrong_chain');
  if (input.status !== 1) throw new Error('failed_receipt');
  if (input.from.toLowerCase() !== input.authenticatedWallet.toLowerCase()) {
    throw new Error('sender_mismatch');
  }
  if (input.to.toLowerCase() !== input.allowedSettler.toLowerCase()) {
    throw new Error('unexpected_destination');
  }
}
```

Replace `apps/api/src/trades/routes.ts` with:

```ts
import { desc, eq } from 'drizzle-orm';
import { Hono } from 'hono';
import { z } from 'zod';
import type { Bindings } from '../env';
import { requireAppSession, type AuthVariables } from '../auth/middleware';
import { withDb } from '../db/client';
import { appTrades, profiles } from '../db/schema';
import {
  decodeUsdcDirection,
  validateVerifiedTrade,
  type RpcLog,
} from './verifier';

export const tradeRoutes = new Hono<{
  Bindings: Bindings;
  Variables: AuthVariables;
}>();
tradeRoutes.use('*', requireAppSession);

const verifySchema = z.object({
  txHash: z.string().regex(/^0x[a-fA-F0-9]{64}$/),
});

async function rpc<T>(env: Bindings, method: string, params: unknown[]) {
  const response = await fetch(env.BASE_RPC_URL, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ jsonrpc: '2.0', id: 1, method, params }),
  });
  if (!response.ok) throw new Error(`rpc_http_${response.status}`);
  const payload = await response.json() as { result: T | null };
  if (payload.result == null) throw new Error('rpc_result_missing');
  return payload.result;
}

tradeRoutes.post('/trades/verify', async (context) => {
  const { txHash } = verifySchema.parse(await context.req.json());
  const receipt = await rpc<{
    status: string;
    from: string;
    to: string;
    blockNumber: string;
    logs: RpcLog[];
  }>(context.env, 'eth_getTransactionReceipt', [txHash]);
  const transaction = await rpc<{
    value: string;
  }>(context.env, 'eth_getTransactionByHash', [txHash]);

  const walletAddress = context.get('walletAddress');
  validateVerifiedTrade({
    chainId: 8453,
    status: Number.parseInt(receipt.status, 16),
    from: receipt.from,
    to: receipt.to,
    authenticatedWallet: walletAddress,
    allowedSettler: context.env.ZEROX_SETTLER,
  });

  const direction = decodeUsdcDirection({
    logs: receipt.logs,
    walletAddress,
    usdcAddress: context.env.BASE_USDC_ADDRESS,
  });

  const profile = await withDb(context.env, async (db) => (
    await db.select().from(profiles)
      .where(eq(profiles.walletAddress, walletAddress)).limit(1)
  )[0]);
  if (!profile) return context.json({ error: 'profile_not_found' }, 404);

  const nativeValue = BigInt(transaction.value);
  const record = direction.side === 'buy_eth'
    ? {
        sellToken: context.env.BASE_USDC_ADDRESS,
        buyToken: 'native:8453',
        sellAmount: direction.usdcAmount,
        buyAmount: null,
      }
    : {
        sellToken: 'native:8453',
        buyToken: context.env.BASE_USDC_ADDRESS,
        sellAmount: nativeValue,
        buyAmount: direction.usdcAmount,
      };

  await withDb(context.env, (db) => db.insert(appTrades).values({
    profileId: profile.id,
    chainId: 8453,
    txHash,
    ...record,
    metadata: {
      side: direction.side,
      receiptBlock: receipt.blockNumber,
      nativeBuyAmountUnavailable: direction.side === 'buy_eth',
    },
    executedAt: new Date(),
  }).onConflictDoNothing());

  return context.json({ txHash, verified: true, side: direction.side });
});

tradeRoutes.get('/trades', async (context) => {
  const profile = await withDb(context.env, async (db) => (
    await db.select().from(profiles)
      .where(eq(profiles.walletAddress, context.get('walletAddress'))).limit(1)
  )[0]);
  if (!profile) return context.json({ error: 'profile_not_found' }, 404);

  const rows = await withDb(context.env, (db) => db.select().from(appTrades)
    .where(eq(appTrades.profileId, profile.id))
    .orderBy(desc(appTrades.executedAt)).limit(100));
  return context.json({ trades: rows });
});
```

Extend `Bindings` with exact values used above:

```ts
BASE_RPC_URL: string;
BASE_USDC_ADDRESS: string;
```

Extend `trades.test.ts` with fixed USDC `Transfer` log fixtures for both directions. Assert that the inserted USDC amount is decoded from log `data`, the ETH sell amount is decoded from transaction `value`, and request JSON contains only `txHash`.

- [ ] **Step 5: Implement Flutter settings repository and controller**

Create `apps/mobile/lib/features/settings/settings_models.dart`:

```dart
enum AppAppearance { system, light, dark }

final class AppSettings {
  const AppSettings({
    required this.locale,
    required this.appearance,
    required this.preferBiometrics,
  });
  final String locale;
  final AppAppearance appearance;
  final bool preferBiometrics;
}
```

Create `apps/mobile/lib/features/settings/settings_repository.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:dex_app/features/settings/settings_models.dart';

final class SettingsRepository {
  SettingsRepository(this._dio);
  final Dio _dio;

  Future<AppSettings> update(AppSettings settings) async {
    final response = await _dio.put<Map<String, Object?>>('/v1/settings', data: {
      'locale': settings.locale,
      'appearance': settings.appearance.name,
      'displayCurrency': 'USD',
      'preferBiometrics': settings.preferBiometrics,
    });
    final json = response.data!;
    return AppSettings(
      locale: json['locale']! as String,
      appearance: AppAppearance.values.byName(json['appearance']! as String),
      preferBiometrics: json['preferBiometrics']! as bool,
    );
  }
}
```

Create `apps/mobile/lib/features/settings/settings_controller.dart`:

```dart
import 'package:dex_app/features/settings/settings_models.dart';
import 'package:dex_app/features/settings/settings_repository.dart';
import 'package:flutter/foundation.dart';

final class SettingsController extends ChangeNotifier {
  SettingsController(this._repository, this._settings);
  final SettingsRepository _repository;
  AppSettings _settings;

  AppSettings get settings => _settings;

  Future<void> update({
    String? locale,
    AppAppearance? appearance,
    bool? preferBiometrics,
  }) async {
    final next = AppSettings(
      locale: locale ?? _settings.locale,
      appearance: appearance ?? _settings.appearance,
      preferBiometrics: preferBiometrics ?? _settings.preferBiometrics,
    );
    _settings = await _repository.update(next);
    notifyListeners();
  }

  bool get deviceAuthenticationRequiredForHighRiskActions => true;
}
```

Create `apps/mobile/lib/features/settings/settings_screen.dart`:

```dart
import 'package:dex_app/features/settings/settings_controller.dart';
import 'package:dex_app/features/settings/settings_models.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    required this.controller,
    required this.walletAddress,
    required this.onLogout,
    super.key,
  });

  final SettingsController controller;
  final String walletAddress;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final settings = controller.settings;
        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: ListView(
            children: [
              ListTile(title: const Text('Wallet'), subtitle: Text(walletAddress)),
              DropdownButtonFormField<String>(
                value: settings.locale,
                items: const [
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'zh', child: Text('简体中文')),
                ],
                onChanged: (value) {
                  if (value != null) controller.update(locale: value);
                },
              ),
              DropdownButtonFormField<AppAppearance>(
                value: settings.appearance,
                items: [
                  for (final value in AppAppearance.values)
                    DropdownMenuItem(value: value, child: Text(value.name)),
                ],
                onChanged: (value) {
                  if (value != null) controller.update(appearance: value);
                },
              ),
              SwitchListTile(
                value: settings.preferBiometrics,
                title: const Text('Prefer biometrics'),
                subtitle: const Text(
                  'Device authentication remains required for Approve, Swap, and Withdraw.',
                ),
                onChanged: (value) => controller.update(preferBiometrics: value),
              ),
              const ListTile(
                title: Text('Risk disclosure'),
                subtitle: Text('On-chain transactions are irreversible.'),
              ),
              ListTile(
                title: const Text('Sign out'),
                onTap: onLogout,
              ),
            ],
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 6: Verify and commit**

```bash
cd apps/api
npm run typecheck
npm test
cd ../mobile
flutter analyze
flutter test test/features/settings test/features/market

git add apps
git commit -m "feat: add authenticated user data and verified trades"
```

---

### Task 12: Add Deposit, Withdraw, and Activity

**Files:**
- Create: `apps/mobile/lib/features/portfolio/deposit_sheet.dart`
- Create: `apps/mobile/lib/features/portfolio/withdraw_models.dart`
- Create: `apps/mobile/lib/features/portfolio/withdraw_controller.dart`
- Create: `apps/mobile/lib/features/portfolio/withdraw_screen.dart`
- Create: `apps/mobile/lib/features/portfolio/activity_models.dart`
- Create: `apps/mobile/lib/features/portfolio/activity_controller.dart`
- Modify: `apps/mobile/lib/features/portfolio/portfolio_screen.dart`
- Modify: `apps/mobile/lib/app/router.dart`
- Test: `apps/mobile/test/features/portfolio/withdraw_controller_test.dart`
- Test: `apps/mobile/test/features/portfolio/deposit_sheet_test.dart`

**Interfaces:**
- Consumes: `WalletService`, `BiometricGate`, `TransactionService`, pending store, verified trade API.
- Produces: receive QR, `WithdrawController`, unified `ActivityItem` list.

- [ ] **Step 1: Write withdrawal validation tests**

Create `apps/mobile/test/features/portfolio/withdraw_controller_test.dart`:

```dart
import 'package:dex_app/features/portfolio/withdraw_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rejects invalid address, zero amount, and USDC precision above six', () {
    const controller = WithdrawController();
    expect(controller.validate(address: 'bad', amount: '1', decimals: 6), 'invalid_address');
    expect(controller.validate(address: '0x1111111111111111111111111111111111111111', amount: '0', decimals: 6), 'invalid_amount');
    expect(controller.validate(address: '0x1111111111111111111111111111111111111111', amount: '1.0000001', decimals: 6), 'too_many_decimals');
  });
}
```

- [ ] **Step 2: Run test and verify red state**

```bash
flutter pub add qr_flutter
flutter test test/features/portfolio/withdraw_controller_test.dart
```

Expected: missing controller.

- [ ] **Step 3: Implement Deposit sheet**

Create `apps/mobile/lib/features/portfolio/deposit_sheet.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

class DepositSheet extends StatelessWidget {
  const DepositSheet({required this.address, super.key});
  final String address;

  @override
  Widget build(BuildContext context) {
    final payload = 'ethereum:$address@8453';
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Deposit on Base'),
            const SizedBox(height: 16),
            QrImageView(data: payload, size: 220),
            const SizedBox(height: 16),
            SelectableText(address),
            TextButton.icon(
              onPressed: () => Clipboard.setData(ClipboardData(text: address)),
              icon: const Icon(Icons.copy),
              label: const Text('Copy address'),
            ),
            const Text('Only send supported assets on Base. Assets sent on another network may not appear.'),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Implement withdrawal amount parsing and transaction creation**

Create `apps/mobile/lib/features/portfolio/withdraw_controller.dart`:

```dart
final class WithdrawController {
  const WithdrawController();

  String? validate({
    required String address,
    required String amount,
    required int decimals,
  }) {
    if (!RegExp(r'^0x[a-fA-F0-9]{40}$').hasMatch(address)) return 'invalid_address';
    final parts = amount.split('.');
    final whole = BigInt.tryParse(parts.first);
    if (whole == null || (parts.length == 1 && whole <= BigInt.zero)) return 'invalid_amount';
    if (parts.length > 2) return 'invalid_amount';
    final fraction = parts.length == 2 ? parts[1] : '';
    if (fraction.length > decimals) return 'too_many_decimals';
    final raw = BigInt.parse('${parts.first}${fraction.padRight(decimals, '0')}');
    if (raw <= BigInt.zero) return 'invalid_amount';
    return null;
  }

  BigInt toRawAmount(String amount, int decimals) {
    final parts = amount.split('.');
    final fraction = parts.length == 2 ? parts[1] : '';
    return BigInt.parse('${parts.first}${fraction.padRight(decimals, '0')}');
  }
}
```

Create `withdraw_screen.dart` using `HookWidget` for address and amount controllers. On Confirm:

1. validate input;
2. authenticate through `BiometricGate`;
3. build ETH value transfer or USDC `transfer(address,uint256)` calldata;
4. sign through `WalletService.signTransaction()`;
5. broadcast through `ChainGateway`;
6. store a `PendingTransaction(operation: withdraw)`;
7. show the shared transaction timeline.

Do not create a second signer, biometric implementation, or pending store.

- [ ] **Step 5: Implement unified activity model and controller**

Create `apps/mobile/lib/features/portfolio/activity_models.dart`:

```dart
enum ActivityStatus { pending, confirmed, failed }
enum ActivityType { approve, swap, deposit, withdraw }

final class ActivityItem {
  const ActivityItem({
    required this.type,
    required this.status,
    required this.title,
    required this.txHash,
    required this.timestamp,
  });
  final ActivityType type;
  final ActivityStatus status;
  final String title;
  final String txHash;
  final DateTime timestamp;

  String get explorerUrl => 'https://basescan.org/tx/$txHash';
}
```

`ActivityController.load()` merges pending local transactions with `/v1/trades`, deduplicates by lowercase Tx Hash, and sorts descending by timestamp. Confirmed server records replace matching local pending rows.

- [ ] **Step 6: Verify and commit**

```bash
flutter analyze
flutter test test/features/portfolio

git add apps/mobile
git commit -m "feat: add funding and activity flows"
```

---

### Task 13: Add Responsive Goldens, Integration, Security, and Demo

**Files:**
- Create: `apps/mobile/test/goldens/market_golden_test.dart`
- Create: `apps/mobile/test/goldens/trade_golden_test.dart`
- Create: `apps/mobile/test/goldens/portfolio_golden_test.dart`
- Create: `apps/mobile/integration_test/trade_flow_test.dart`
- Create: `docs/architecture.md`
- Create: `docs/security.md`
- Create: `docs/demo-script.md`
- Modify: `.github/workflows/ci.yml`
- Modify: `README.md`

**Interfaces:**
- Consumes: all production interfaces from Tasks 1–12.
- Produces: bounded golden suite, mocked end-to-end test, release gates, architecture/security documentation, two-minute demo script.

- [ ] **Step 1: Add a deterministic golden harness**

Create a helper that fixes size, locale, theme, text scale, and mock providers. Golden cases are limited to:

```text
390x844 en light: Market, Pair Detail, Trade, Confirmation, Portfolio
390x844 zh dark: Market, Trade, Portfolio
320x568 en light: Market, Trade
1024x768 en light: Market split, Trade split
390x844 text scale 2.0: Confirmation, Settings
390x844 states: Market error, Quote loading, Tx success
```

Total target: 17–20 images.

Each golden test must call `matchesGoldenFile()` with a deterministic file name and must not contact RPC, Web3Auth, Supabase, CoinGecko, or 0x.

- [ ] **Step 2: Add mocked end-to-end Trade integration test**

Create `apps/mobile/integration_test/trade_flow_test.dart` that overrides Riverpod dependencies with fakes and executes:

```text
restore wallet
→ restore app session
→ open ETH detail
→ enter 1,000,000 USDC base units
→ receive Price
→ tap Review
→ receive Quote
→ confirm device auth
→ exact Approve
→ approval confirmed
→ Swap submitted
→ receipt confirmed
→ Portfolio refresh
```

Assert the fake log order and that the final Portfolio value changes.

- [ ] **Step 3: Add Worker integration fixtures**

Add tests for:

- SIWE nonce replay;
- unsupported Swap pair;
- unexpected allowance spender;
- unexpected transaction destination;
- failed receipt;
- sender mismatch;
- duplicate `(chainId, txHash)` insertion;
- valid USDC→ETH transfer-log decoding.

Use recorded minimal JSON fixtures checked into `apps/api/test/fixtures`; do not call production providers in CI.

- [ ] **Step 4: Write architecture and security documents**

`docs/architecture.md` must contain:

- repository map;
- shallow Flutter feature convention;
- Riverpod dependency graph;
- Worker route contracts;
- SIWE sequence;
- Price→Quote sequence;
- Approve→Swap sequence;
- pending recovery sequence;
- database table responsibilities.

`docs/security.md` must contain:

- wallet key lifecycle and adapter boundary;
- device-auth limitations;
- SIWE domain/URI/chain/nonce checks;
- JWT storage and expiry;
- 0x allowlists;
- exact approval policy;
- receipt/log verification;
- logging redaction;
- restricted database role;
- staging mainnet verification limits;
- explicit statement that audit completion is not claimed.

- [ ] **Step 5: Add CI release gates**

Extend `.github/workflows/ci.yml` with:

```yaml
      - run: flutter gen-l10n
        working-directory: apps/mobile
      - run: dart run build_runner build --delete-conflicting-outputs
        working-directory: apps/mobile
      - run: git diff --exit-code -- apps/mobile/lib/l10n apps/mobile/lib -- '*.g.dart' '*.freezed.dart'
      - run: flutter test --update-goldens=false
        working-directory: apps/mobile
      - run: |
          ! grep -R -n -E 'getPrivateKeyForSigning|BEGIN PRIVATE KEY|ZEROX_API_KEY=' apps docs
```

Run integration tests on a configured emulator job rather than the normal unit-test job.

- [ ] **Step 6: Write two-minute demo script**

Create `docs/demo-script.md`:

```text
0:00–0:15  Market catalog, responsive layout, English/Chinese switch
0:15–0:30  ETH detail, chart, only ETH/USDC marked Tradable
0:30–0:45  Web3Auth wallet restoration and address
0:45–1:05  Price while editing, Review, firm Quote details
1:05–1:30  Device auth, exact USDC Approve, Swap timeline
1:30–1:45  Tx Hash, Base explorer, Portfolio refresh
1:45–2:00  Architecture, automated tests, security boundaries
```

- [ ] **Step 7: Run full release verification**

```bash
cd apps/mobile
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
git diff --exit-code -- '*.g.dart' '*.freezed.dart'
flutter analyze
flutter test
flutter test integration_test/trade_flow_test.dart
cd ../api
npm ci
npm run typecheck
npm test
cd ../..
git status --short
```

Expected: every test/build command exits `0`; `git status --short` shows only reviewed documentation or golden updates intended for the final commit.

- [ ] **Step 8: Commit**

```bash
git add .
git commit -m "test: harden Flutter DEX release flow"
```

---

## Phase 4 and Product Completion Checkpoint

Before claiming completion:

1. Re-read the approved design and map every V1 requirement to a test or task.
2. Confirm all explicit exclusions remain absent.
3. Run the full release verification from Task 13.
4. Perform one controlled low-value Base mainnet Swap with a dedicated staging wallet only after manually comparing chain ID, sell amount, minimum received, spender, destination, and Gas against the Quote.
5. Use `superpowers:finishing-a-development-branch` to decide merge, pull request, or cleanup.
