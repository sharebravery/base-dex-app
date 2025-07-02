# Flutter DEX V1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a polished three-tab Flutter DEX for Base with Web3Auth embedded accounts, live market data, real 0x Swap API quotes, biometric confirmation, on-chain execution, and portfolio refresh.

**Architecture:** Use a feature-first Flutter app with Riverpod-generated providers and explicit domain interfaces. A small Hono Cloudflare Worker normalizes CoinGecko market data and 0x quotes while keeping provider keys out of the mobile binary. The Flutter app signs Base transactions locally through a Web3Auth-recovered EVM key and tracks receipts through an RPC provider.

**Tech Stack:** Flutter/Dart, Riverpod 3, go_router, Dio, Freezed/json_serializable, fl_chart, Web3Auth Flutter SDK, web3dart, local_auth, flutter_secure_storage, shared_preferences, Hono, Cloudflare Workers, TypeScript, Zod, Vitest, 0x Swap API, CoinGecko API, Base mainnet.

## Global Constraints

- Target iOS 14+ and Android API 26+ because the embedded-wallet SDK requires those floors.
- Support exactly one chain in V1: Base mainnet, chain ID `8453`.
- Start with the curated `ETH/USDC` market; add more pairs only by editing the token registry.
- Use standard Web3 terminology: Swap, Gas, Slippage, Approve, Liquidity, Route, Tx Hash.
- Keep private keys out of logs, backend storage, crash reports, analytics, and persistent Flutter storage.
- Require explicit confirmation and local device authentication before every Approve, Swap, or Withdraw signature.
- Keep provider API keys in Cloudflare Worker secrets; never compile them into Flutter.
- Use `Decimal` or integer token units for financial calculations; never use `double` for token amounts.
- Commit generated `*.freezed.dart`, `*.g.dart`, and `pubspec.lock` files for reproducible builds.
- Every task ends with `flutter analyze`, focused tests, and a Git commit.

---

## Repository Map

```text
.
├── apps/
│   ├── mobile/
│   │   ├── lib/
│   │   │   ├── app/
│   │   │   ├── core/
│   │   │   └── features/
│   │   │       ├── auth/
│   │   │       ├── market/
│   │   │       ├── portfolio/
│   │   │       ├── settings/
│   │   │       └── trade/
│   │   └── test/
│   └── api/
│       ├── src/
│       │   ├── market/
│       │   ├── swap/
│       │   └── index.ts
│       └── test/
├── docs/
│   └── architecture.md
└── .github/workflows/ci.yml
```

The mobile app consumes only normalized `/v1/markets`, `/v1/candles`, and `/v1/swap/quote` contracts. Provider-specific JSON remains inside `apps/api`.

---

### Task 1: Bootstrap the Flutter App, Worker, and CI

**Files:**
- Create: `apps/mobile/pubspec.yaml`
- Create: `apps/mobile/analysis_options.yaml`
- Create: `apps/mobile/lib/main.dart`
- Create: `apps/mobile/lib/app/app.dart`
- Create: `apps/api/package.json`
- Create: `apps/api/tsconfig.json`
- Create: `apps/api/wrangler.jsonc`
- Create: `apps/api/src/index.ts`
- Create: `.github/workflows/ci.yml`
- Test: `apps/mobile/test/app_smoke_test.dart`
- Test: `apps/api/test/health.test.ts`

**Interfaces:**
- Produces: `DexApp`, `GET /health`, Flutter and Worker test commands used by every later task.

- [ ] **Step 1: Create both applications and pin dependencies**

Run:

```bash
mkdir -p apps
flutter create --org com.cloudysky --project-name dex_app apps/mobile
mkdir -p apps/api/src apps/api/test
```

Replace `apps/mobile/pubspec.yaml` dependency sections with:

```yaml
environment:
  sdk: ">=3.8.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  decimal: ^3.2.4
  dio: ^5.10.0
  fl_chart: ^1.2.0
  flutter_riverpod: ^3.3.2
  flutter_secure_storage: ^10.3.1
  flutter_svg: ^2.3.0
  freezed_annotation: ^3.1.0
  go_router: ^17.3.0
  intl: ^0.20.3
  json_annotation: ^4.12.0
  local_auth: ^3.0.2
  qr_flutter: ^4.1.0
  riverpod_annotation: ^4.0.3
  shared_preferences: ^2.5.5
  web3auth_flutter: ^6.3.0
  web3dart: ^3.0.3

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.15.2
  custom_lint: ^0.8.1
  flutter_lints: ^6.0.0
  freezed: ^3.2.5
  json_serializable: ^6.14.0
  mocktail: ^1.0.5
  riverpod_generator: ^4.0.4
  riverpod_lint: ^3.1.4
```

Create `apps/api/package.json`:

```json
{
  "name": "dex-api",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "wrangler dev",
    "deploy": "wrangler deploy",
    "test": "vitest run",
    "typecheck": "tsc --noEmit"
  },
  "dependencies": {
    "hono": "4.12.30",
    "zod": "4.4.3"
  },
  "devDependencies": {
    "@cloudflare/workers-types": "5.20260715.1",
    "typescript": "7.0.2",
    "vitest": "4.1.10",
    "wrangler": "4.111.0"
  }
}
```

- [ ] **Step 2: Write failing smoke tests**

Create `apps/mobile/test/app_smoke_test.dart`:

```dart
import 'package:dex_app/app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the Market tab', (tester) async {
    await tester.pumpWidget(const DexApp());
    expect(find.text('Market'), findsWidgets);
  });
}
```

Create `apps/api/test/health.test.ts`:

```ts
import { describe, expect, it } from 'vitest';
import app from '../src/index';

describe('GET /health', () => {
  it('returns ok', async () => {
    const response = await app.request('/health');
    expect(response.status).toBe(200);
    expect(await response.json()).toEqual({ status: 'ok' });
  });
});
```

Run:

```bash
cd apps/mobile && flutter test test/app_smoke_test.dart
cd ../api && npm install && npm test
```

Expected: both suites fail because `DexApp` and the Hono route do not exist.

- [ ] **Step 3: Add the minimal app and Worker entrypoints**

Create `apps/mobile/lib/app/app.dart`:

```dart
import 'package:flutter/cupertino.dart';

class DexApp extends StatelessWidget {
  const DexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      debugShowCheckedModeBanner: false,
      home: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(middle: Text('Market')),
        child: SafeArea(child: Center(child: Text('Market'))),
      ),
    );
  }
}
```

Replace `apps/mobile/lib/main.dart`:

```dart
import 'package:dex_app/app/app.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: DexApp()));
}
```

Create `apps/api/src/index.ts`:

```ts
import { Hono } from 'hono';

const app = new Hono();
app.get('/health', (context) => context.json({ status: 'ok' }));

export default app;
```

- [ ] **Step 4: Add static analysis and CI**

Create `apps/mobile/analysis_options.yaml`:

```yaml
include: package:flutter_lints/flutter.yaml

plugins:
  riverpod_lint: 3.1.4

linter:
  rules:
    always_use_package_imports: true
    avoid_print: true
    prefer_final_locals: true
    unawaited_futures: true
```

Create `.github/workflows/ci.yml`:

```yaml
name: ci
on: [push, pull_request]
jobs:
  mobile:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true
      - run: flutter pub get
        working-directory: apps/mobile
      - run: dart run build_runner build --delete-conflicting-outputs
        working-directory: apps/mobile
      - run: flutter analyze
        working-directory: apps/mobile
      - run: flutter test
        working-directory: apps/mobile
  api:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: npm
          cache-dependency-path: apps/api/package-lock.json
      - run: npm ci
        working-directory: apps/api
      - run: npm run typecheck
        working-directory: apps/api
      - run: npm test
        working-directory: apps/api
```

- [ ] **Step 5: Verify and commit**

Run:

```bash
cd apps/mobile
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
cd ../api
npm install
npm run typecheck
npm test
```

Expected: all commands pass.

```bash
git add apps .github
git commit -m "chore: bootstrap Flutter DEX workspace"
```

---

### Task 2: Build the Apple-Inspired Design System and Three-Tab Shell

**Files:**
- Create: `apps/mobile/lib/app/router.dart`
- Create: `apps/mobile/lib/app/shell/dex_shell.dart`
- Create: `apps/mobile/lib/core/theme/app_colors.dart`
- Create: `apps/mobile/lib/core/theme/app_spacing.dart`
- Create: `apps/mobile/lib/core/theme/app_theme.dart`
- Create: `apps/mobile/lib/core/widgets/app_card.dart`
- Create: `apps/mobile/lib/features/market/presentation/market_screen.dart`
- Create: `apps/mobile/lib/features/trade/presentation/trade_screen.dart`
- Create: `apps/mobile/lib/features/portfolio/presentation/portfolio_screen.dart`
- Modify: `apps/mobile/lib/app/app.dart`
- Test: `apps/mobile/test/app/navigation_test.dart`

**Interfaces:**
- Produces: routes `/market`, `/trade`, `/portfolio`; reusable `AppCard`; light/dark theme tokens.

- [ ] **Step 1: Write the navigation test**

```dart
import 'package:dex_app/app/app.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('switches among Market, Trade, and Portfolio', (tester) async {
    await tester.pumpWidget(const DexApp());
    expect(find.text('Markets'), findsOneWidget);

    await tester.tap(find.byIcon(CupertinoIcons.arrow_2_circlepath));
    await tester.pumpAndSettle();
    expect(find.text('Swap'), findsOneWidget);

    await tester.tap(find.byIcon(CupertinoIcons.chart_pie));
    await tester.pumpAndSettle();
    expect(find.text('Portfolio'), findsOneWidget);
  });
}
```

Run `flutter test test/app/navigation_test.dart`; expected failure because the shell does not exist.

- [ ] **Step 2: Create design tokens**

Create `app_colors.dart`:

```dart
import 'package:flutter/cupertino.dart';

abstract final class AppColors {
  static const accent = Color(0xFF5B5CF6);
  static const positive = Color(0xFF16A36A);
  static const negative = Color(0xFFE05555);
  static const lightBackground = Color(0xFFF6F7F9);
  static const darkBackground = Color(0xFF0C0D0F);
  static const lightSurface = Color(0xFFFFFFFF);
  static const darkSurface = Color(0xFF17181C);
}
```

Create `app_spacing.dart`:

```dart
abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const radius = 20.0;
}
```

Create `app_card.dart`:

```dart
import 'package:dex_app/core/theme/app_spacing.dart';
import 'package:flutter/cupertino.dart';

class AppCard extends StatelessWidget {
  const AppCard({required this.child, super.key, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final color = brightness == Brightness.dark
        ? const Color(0xFF17181C)
        : CupertinoColors.white;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppSpacing.md),
        child: child,
      ),
    );
  }
}
```

- [ ] **Step 3: Implement the router and tab shell**

Create `router.dart` with a `StatefulShellRoute.indexedStack` and paths `/market`, `/trade`, `/portfolio`. Create `dex_shell.dart` using `CupertinoTabBar` with `CupertinoIcons.chart_bar`, `CupertinoIcons.arrow_2_circlepath`, and `CupertinoIcons.chart_pie`.

The shell constructor must be:

```dart
class DexShell extends StatelessWidget {
  const DexShell({required this.navigationShell, super.key});
  final StatefulNavigationShell navigationShell;
}
```

Each placeholder screen must have a `CupertinoPageScaffold` title matching the test: `Markets`, `Swap`, and `Portfolio`.

- [ ] **Step 4: Wire `DexApp` to the router**

```dart
class DexApp extends StatelessWidget {
  const DexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: const CupertinoThemeData(
        primaryColor: AppColors.accent,
        scaffoldBackgroundColor: AppColors.lightBackground,
      ),
    );
  }
}
```

- [ ] **Step 5: Verify and commit**

```bash
flutter analyze
flutter test test/app/navigation_test.dart
git add apps/mobile/lib apps/mobile/test/app
git commit -m "feat: add DEX design system and navigation shell"
```

---

### Task 3: Define Domain Models, Token Registry, and Formatting

**Files:**
- Create: `apps/mobile/lib/core/config/base_tokens.dart`
- Create: `apps/mobile/lib/core/format/amount_formatter.dart`
- Create: `apps/mobile/lib/features/market/domain/market_pair.dart`
- Create: `apps/mobile/lib/features/market/domain/candle.dart`
- Create: `apps/mobile/lib/features/portfolio/domain/holding.dart`
- Create: `apps/mobile/lib/features/trade/domain/swap_quote.dart`
- Create: `apps/mobile/lib/features/trade/domain/transaction_stage.dart`
- Test: `apps/mobile/test/core/amount_formatter_test.dart`
- Test: `apps/mobile/test/features/trade/transaction_stage_test.dart`

**Interfaces:**
- Produces: `BaseTokens.eth`, `BaseTokens.usdc`, `MarketPair`, `Candle`, `Holding`, `SwapQuote`, `TransactionStage`.

- [ ] **Step 1: Write amount and state tests**

```dart
void main() {
  test('formats token amounts without binary floating-point loss', () {
    expect(formatTokenAmount(Decimal.parse('1234.56789'), maxDecimals: 4), '1,234.5679');
  });

  test('confirmed is terminal and submitted is not', () {
    expect(TransactionStage.confirmed.isTerminal, isTrue);
    expect(TransactionStage.submitted.isTerminal, isFalse);
  });
}
```

Run the two test files and confirm they fail.

- [ ] **Step 2: Create the curated Base token registry**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'base_tokens.freezed.dart';

@freezed
abstract class TokenInfo with _$TokenInfo {
  const factory TokenInfo({
    required String symbol,
    required String name,
    required String address,
    required int decimals,
    required String coingeckoId,
    required bool isNative,
  }) = _TokenInfo;
}

abstract final class BaseTokens {
  static const eth = TokenInfo(
    symbol: 'ETH',
    name: 'Ether',
    address: '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE',
    decimals: 18,
    coingeckoId: 'ethereum',
    isNative: true,
  );

  static const usdc = TokenInfo(
    symbol: 'USDC',
    name: 'USD Coin',
    address: '0x833589fCD6eDb6E08f4c7C32D4f71b54bDa02913',
    decimals: 6,
    coingeckoId: 'usd-coin',
    isNative: false,
  );

  static const all = [eth, usdc];
}
```

- [ ] **Step 3: Add immutable domain models**

`SwapQuote` must expose normalized provider-independent fields:

```dart
@freezed
abstract class SwapQuote with _$SwapQuote {
  const factory SwapQuote({
    required String sellToken,
    required String buyToken,
    required BigInt sellAmount,
    required BigInt buyAmount,
    required BigInt minBuyAmount,
    required String allowanceTarget,
    required String transactionTo,
    required String transactionData,
    required BigInt transactionValue,
    required BigInt gas,
    required DateTime expiresAt,
    required Decimal priceImpactPercent,
    required List<String> routeLabels,
  }) = _SwapQuote;

  factory SwapQuote.fromJson(Map<String, Object?> json) => _$SwapQuoteFromJson(json);
}
```

Define `TransactionStage` as:

```dart
enum TransactionStage {
  preparing,
  awaitingBiometric,
  awaitingSignature,
  approving,
  submitted,
  confirmed,
  failed;

  bool get isTerminal => this == confirmed || this == failed;
}
```

- [ ] **Step 4: Implement exact decimal formatting**

```dart
String formatTokenAmount(Decimal value, {int maxDecimals = 6}) {
  final formatter = NumberFormat.decimalPatternDigits(decimalDigits: maxDecimals);
  final rounded = value.toDouble();
  return formatter.format(rounded).replaceFirst(RegExp(r'\.?0+$'), '');
}
```

Use `Decimal` for arithmetic; conversion to `double` is permitted only at the final UI formatting boundary.

- [ ] **Step 5: Generate, verify, and commit**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test test/core/amount_formatter_test.dart test/features/trade/transaction_stage_test.dart
git add apps/mobile/lib apps/mobile/test
git commit -m "feat: define Base DEX domain models"
```

---

### Task 4: Build the Static Market and Pair Detail Experience

**Files:**
- Create: `apps/mobile/lib/features/market/data/market_fixtures.dart`
- Create: `apps/mobile/lib/features/market/presentation/widgets/market_pair_tile.dart`
- Create: `apps/mobile/lib/features/market/presentation/widgets/sparkline_chart.dart`
- Create: `apps/mobile/lib/features/market/presentation/widgets/candlestick_chart.dart`
- Create: `apps/mobile/lib/features/market/presentation/pair_detail_screen.dart`
- Modify: `apps/mobile/lib/features/market/presentation/market_screen.dart`
- Modify: `apps/mobile/lib/app/router.dart`
- Test: `apps/mobile/test/features/market/market_screen_test.dart`
- Test: `apps/mobile/test/features/market/pair_detail_screen_test.dart`

**Interfaces:**
- Consumes: `MarketPair`, `Candle`, `AppCard`.
- Produces: route `/market/:pairId`; `SparklineChart(points)`; `CandlestickChart(candles)`.

- [ ] **Step 1: Write widget tests for the vertical market flow**

The market test must assert `ETH / USDC`, `$`, and `24h` are visible. The detail test must tap the ETH row, assert the pair title, interval buttons `1H`, `1D`, `1W`, and a `Swap` action.

- [ ] **Step 2: Create deterministic fixtures**

Create 48 hourly candles beginning at a fixed UTC timestamp and a `MarketPair` with price `3240.12`, change `2.41`, and volume `812000000`. Do not use random fixture generation so golden tests remain stable.

- [ ] **Step 3: Implement charts**

Use `fl_chart` for the sparkline. Implement candlesticks with `CustomPainter` so the portfolio demonstrates native Flutter drawing:

```dart
class CandlestickPainter extends CustomPainter {
  CandlestickPainter(this.candles);
  final List<Candle> candles;

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;
    final maxPrice = candles.map((e) => e.high).reduce((a, b) => a > b ? a : b);
    final minPrice = candles.map((e) => e.low).reduce((a, b) => a < b ? a : b);
    final range = (maxPrice - minPrice).toDouble();
    final candleWidth = size.width / candles.length;

    for (var index = 0; index < candles.length; index++) {
      final candle = candles[index];
      double y(Decimal price) =>
          size.height - ((price - minPrice).toDouble() / range) * size.height;
      final x = candleWidth * index + candleWidth / 2;
      final up = candle.close >= candle.open;
      final paint = Paint()
        ..color = up ? const Color(0xFF16A36A) : const Color(0xFFE05555)
        ..strokeWidth = 1.2;
      canvas.drawLine(Offset(x, y(candle.high)), Offset(x, y(candle.low)), paint);
      canvas.drawRect(
        Rect.fromLTRB(
          x - candleWidth * 0.28,
          y(up ? candle.close : candle.open),
          x + candleWidth * 0.28,
          y(up ? candle.open : candle.close),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CandlestickPainter oldDelegate) => oldDelegate.candles != candles;
}
```

- [ ] **Step 4: Build the polished Market and Pair Detail screens**

Use a large title, search field, watchlist card, gainers section, and pair list. Pair detail must show a Hero transition keyed by `pair.id`, a chart crosshair overlay, interval selector, holdings summary placeholder, and sticky `Buy`/`Sell` buttons that navigate to `/trade?pair=eth-usdc&side=buy`.

- [ ] **Step 5: Verify and commit**

```bash
flutter analyze
flutter test test/features/market
git add apps/mobile/lib/features/market apps/mobile/lib/app/router.dart apps/mobile/test/features/market
git commit -m "feat: add polished market and chart experience"
```

---

### Task 5: Add the Market Data Worker and Flutter Repository

**Files:**
- Create: `apps/api/src/env.ts`
- Create: `apps/api/src/market/schema.ts`
- Create: `apps/api/src/market/coingecko-client.ts`
- Create: `apps/api/src/market/routes.ts`
- Modify: `apps/api/src/index.ts`
- Create: `apps/mobile/lib/core/network/api_client.dart`
- Create: `apps/mobile/lib/features/market/data/market_api.dart`
- Create: `apps/mobile/lib/features/market/data/market_repository.dart`
- Create: `apps/mobile/lib/features/market/application/market_providers.dart`
- Modify: market presentation files to consume providers
- Test: `apps/api/test/market.test.ts`
- Test: `apps/mobile/test/features/market/market_repository_test.dart`

**Interfaces:**
- Produces: `GET /v1/markets`, `GET /v1/candles?pair=eth-usdc&interval=1h`; `MarketRepository.watchMarkets()` and `getCandles()`.

- [ ] **Step 1: Write Worker contract tests**

Mock `globalThis.fetch` and assert normalized JSON:

```json
{
  "pairs": [{
    "id": "eth-usdc",
    "baseSymbol": "ETH",
    "quoteSymbol": "USDC",
    "price": "3240.12",
    "change24hPercent": "2.41",
    "volume24hUsd": "812000000"
  }]
}
```

For candles, assert timestamps are ISO-8601 strings and OHLC fields are decimal strings.

- [ ] **Step 2: Implement Zod schemas and CoinGecko adapter**

Use `https://api.coingecko.com/api/v3/simple/price` for current ETH data and `https://api.coingecko.com/api/v3/coins/ethereum/market_chart` for history. Send `x-cg-demo-api-key` only when `COINGECKO_API_KEY` is configured as a Worker secret. Convert all numeric provider values to strings before returning them to Flutter.

- [ ] **Step 3: Add Hono routes and cache headers**

```ts
marketRoutes.get('/markets', async (context) => {
  const result = await client.getMarkets();
  return context.json(result, 200, {
    'Cache-Control': 'public, max-age=10, stale-while-revalidate=20'
  });
});
```

Mount with `app.route('/v1', marketRoutes)`.

- [ ] **Step 4: Add Flutter API and repository layers**

`MarketRepository` must be:

```dart
abstract interface class MarketRepository {
  Future<List<MarketPair>> getMarkets();
  Future<List<Candle>> getCandles({
    required String pairId,
    required CandleInterval interval,
  });
}
```

The Dio client base URL comes from:

```dart
const apiBaseUrl = String.fromEnvironment(
  'DEX_API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8787',
);
```

Use Riverpod `@riverpod` providers and preserve the last successful market list while refresh is in progress.

- [ ] **Step 5: Verify and commit**

```bash
cd apps/api && npm run typecheck && npm test
cd ../mobile && dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test test/features/market/market_repository_test.dart test/features/market
git add apps/api apps/mobile/lib/core/network apps/mobile/lib/features/market apps/mobile/test/features/market
git commit -m "feat: connect live market data"
```

---

### Task 6: Integrate Web3Auth Embedded Account and Session Recovery

**Files:**
- Create: `apps/mobile/lib/features/auth/domain/auth_session.dart`
- Create: `apps/mobile/lib/features/auth/data/embedded_wallet_gateway.dart`
- Create: `apps/mobile/lib/features/auth/data/web3auth_wallet_gateway.dart`
- Create: `apps/mobile/lib/features/auth/application/auth_controller.dart`
- Create: `apps/mobile/lib/features/auth/presentation/sign_in_screen.dart`
- Modify: `apps/mobile/lib/app/router.dart`
- Modify: `apps/mobile/ios/Podfile`
- Modify: Android Gradle configuration generated by Flutter
- Test: `apps/mobile/test/features/auth/auth_controller_test.dart`

**Interfaces:**
- Produces: `AuthSession(address, email, displayName)` and `EmbeddedWalletGateway.signTransaction(...)` capability used by trading.

- [ ] **Step 1: Write controller tests with a fake gateway**

Test these cases: restore existing session, Google login success, Apple login cancellation, email-passwordless login success, logout clears session. The fake gateway returns address `0x1111111111111111111111111111111111111111`.

- [ ] **Step 2: Define the gateway boundary**

```dart
enum EmbeddedLoginMethod { google, apple, emailPasswordless }

abstract interface class EmbeddedWalletGateway {
  Future<void> initialize();
  Future<AuthSession?> restoreSession();
  Future<AuthSession> login(EmbeddedLoginMethod method);
  Future<String> getPrivateKeyForSigning();
  Future<void> logout();
}
```

`getPrivateKeyForSigning()` must never be called by presentation widgets and must not be persisted.

- [ ] **Step 3: Implement Web3Auth initialization**

Read the client ID through `String.fromEnvironment('WEB3AUTH_CLIENT_ID')`. Fail startup with a typed `AuthConfigurationException` when it is empty. Initialize `Network.sapphire_mainnet`, platform redirect URLs, and call `Web3AuthFlutter.initialize()` to restore active sessions. Map SDK cancellation exceptions to `AuthCancelledException`.

- [ ] **Step 4: Configure platforms and sign-in UI**

Set iOS deployment target to `14.0` and Android min SDK to `26`. Configure the Web3Auth callback scheme in both platform projects. Build a calm sign-in page with Apple, Google, and email actions; display the sentence “Your embedded wallet is recoverable through your login.”

- [ ] **Step 5: Add auth router redirects**

Unauthenticated users go to `/sign-in`; authenticated users go to `/market`. Avoid redirect loops by deriving router refresh from `authControllerProvider`.

- [ ] **Step 6: Verify and commit**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test test/features/auth
git add apps/mobile
git commit -m "feat: add recoverable embedded wallet login"
```

---

### Task 7: Load Base Balances and Build the Portfolio

**Files:**
- Create: `apps/mobile/lib/core/web3/base_chain.dart`
- Create: `apps/mobile/lib/core/web3/erc20_abi.dart`
- Create: `apps/mobile/lib/core/web3/evm_client.dart`
- Create: `apps/mobile/lib/features/portfolio/data/portfolio_repository.dart`
- Create: `apps/mobile/lib/features/portfolio/application/portfolio_controller.dart`
- Create: `apps/mobile/lib/features/portfolio/presentation/widgets/holding_tile.dart`
- Modify: `apps/mobile/lib/features/portfolio/presentation/portfolio_screen.dart`
- Test: `apps/mobile/test/features/portfolio/portfolio_controller_test.dart`

**Interfaces:**
- Produces: `EvmClient.getNativeBalance`, `getErc20Balance`, `getAllowance`, `sendRawTransaction`, `getReceipt`; `PortfolioRepository.load(address)`.

- [ ] **Step 1: Write portfolio calculation tests**

Given `0.25 ETH` at `$3,200` and `500 USDC` at `$1`, assert total value is `$1,300`, allocation is `61.538...% ETH`, and balances are preserved as integer base units.

- [ ] **Step 2: Define the Base RPC client**

```dart
abstract final class BaseChain {
  static const chainId = 8453;
  static const rpcUrl = String.fromEnvironment('BASE_RPC_URL');
}
```

`EvmClient` wraps `Web3Client` and exposes only domain-safe operations. Parse the minimal ERC-20 ABI containing `balanceOf`, `allowance`, `approve`, and `transfer`.

- [ ] **Step 3: Implement curated balance loading**

Query native ETH and USDC concurrently. Convert raw `BigInt` values to `Decimal` only when constructing display holdings. Use current prices from `MarketRepository`, and return a typed stale-price state when market data cannot refresh.

- [ ] **Step 4: Build the Portfolio screen**

Show total value, 24-hour change, allocation ring, ETH and USDC holdings, `Deposit`, `Withdraw`, and history placeholders. Animate total-value changes with `TweenAnimationBuilder<double>` only after values are converted to display doubles.

- [ ] **Step 5: Verify and commit**

```bash
flutter analyze
flutter test test/features/portfolio
git add apps/mobile/lib/core/web3 apps/mobile/lib/features/portfolio apps/mobile/test/features/portfolio
git commit -m "feat: add Base portfolio balances"
```

---

### Task 8: Add 0x Quote Proxy and Trade Form State Machine

**Files:**
- Create: `apps/api/src/swap/schema.ts`
- Create: `apps/api/src/swap/zero-x-client.ts`
- Create: `apps/api/src/swap/routes.ts`
- Modify: `apps/api/src/index.ts`
- Create: `apps/mobile/lib/features/trade/data/swap_api.dart`
- Create: `apps/mobile/lib/features/trade/data/swap_repository.dart`
- Create: `apps/mobile/lib/features/trade/application/trade_state.dart`
- Create: `apps/mobile/lib/features/trade/application/trade_controller.dart`
- Modify: `apps/mobile/lib/features/trade/presentation/trade_screen.dart`
- Test: `apps/api/test/swap.test.ts`
- Test: `apps/mobile/test/features/trade/trade_controller_test.dart`

**Interfaces:**
- Produces: `POST /v1/swap/quote`; `SwapRepository.getQuote`; debounced `TradeController`.

- [ ] **Step 1: Write quote normalization tests**

Assert the Worker forwards only chain ID `8453`, curated token addresses, positive sell amounts, and slippage between `0.1` and `3.0`. Assert provider `issues.allowance.spender`, transaction fields, route fills, `minBuyAmount`, and expiry become the normalized `SwapQuote` JSON.

- [ ] **Step 2: Implement the Worker route**

Request `https://api.0x.org/swap/allowance-holder/quote` with headers:

```ts
{
  '0x-api-key': env.ZEROX_API_KEY,
  '0x-version': 'v2'
}
```

Send `chainId=8453`, `sellToken`, `buyToken`, `sellAmount`, `taker`, and `slippageBps`. Reject any token not in the server-side allowlist.

- [ ] **Step 3: Define the trade state machine**

```dart
@freezed
abstract class TradeState with _$TradeState {
  const factory TradeState({
    required TokenInfo sellToken,
    required TokenInfo buyToken,
    @Default('') String amountText,
    @Default(50) int slippageBps,
    SwapQuote? quote,
    @Default(false) bool isLoadingQuote,
    String? validationMessage,
  }) = _TradeState;
}
```

The controller waits 350 ms after input changes, cancels the previous Dio request, and discards responses whose request key no longer matches the current pair, amount, address, and slippage.

- [ ] **Step 4: Build the real Trade screen**

Include pair header, compact chart, Buy/Sell segmented control, token/fiat amount switch, available balance, quote output, and expandable Route/Gas/Slippage/Price Impact details. Disable confirmation when the quote is missing, expired, or price impact exceeds `5%`.

- [ ] **Step 5: Verify and commit**

```bash
cd apps/api && npm run typecheck && npm test
cd ../mobile && dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test test/features/trade/trade_controller_test.dart
git add apps/api/src/swap apps/api/test/swap.test.ts apps/mobile/lib/features/trade apps/mobile/test/features/trade
git commit -m "feat: add live 0x swap quotes"
```

---

### Task 9: Execute Approve and Swap with Biometric Confirmation

**Files:**
- Create: `apps/mobile/lib/core/security/biometric_gate.dart`
- Create: `apps/mobile/lib/features/trade/data/transaction_signer.dart`
- Create: `apps/mobile/lib/features/trade/application/trade_executor.dart`
- Create: `apps/mobile/lib/features/trade/presentation/confirmation_sheet.dart`
- Create: `apps/mobile/lib/features/trade/presentation/transaction_timeline.dart`
- Test: `apps/mobile/test/features/trade/trade_executor_test.dart`
- Test: `apps/mobile/test/features/trade/confirmation_sheet_test.dart`

**Interfaces:**
- Consumes: `EmbeddedWalletGateway.getPrivateKeyForSigning`, `EvmClient`, `SwapQuote`.
- Produces: `TradeExecutionResult(approvalTxHash, swapTxHash)` and observable `TransactionStage` changes.

- [ ] **Step 1: Write execution-order tests**

Test these exact sequences:

1. Native ETH sell: biometric → swap sign → broadcast.
2. USDC allowance sufficient: biometric → swap sign → broadcast.
3. USDC allowance insufficient: biometric → approve sign → approval receipt → swap sign → broadcast.
4. Biometric rejected: no key request and no transaction.

- [ ] **Step 2: Implement the biometric boundary**

```dart
abstract interface class BiometricGate {
  Future<bool> authenticate({required String reason});
}

class LocalAuthBiometricGate implements BiometricGate {
  LocalAuthBiometricGate(this._localAuth);
  final LocalAuthentication _localAuth;

  @override
  Future<bool> authenticate({required String reason}) => _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
}
```

- [ ] **Step 3: Implement signing without persisting the key**

`TransactionSigner` obtains the Web3Auth private key immediately before signing, constructs `EthPrivateKey.fromHex`, signs with chain ID `8453`, clears local references in a `finally` block, and never logs transaction calldata or key material.

- [ ] **Step 4: Implement approval and swap execution**

For ERC-20 sells, read allowance for the exact `allowanceTarget`. If insufficient, encode `approve(spender, sellAmount)` rather than unlimited approval. Wait for approval confirmation before signing the swap transaction from the normalized 0x payload.

- [ ] **Step 5: Build the confirmation-to-timeline transition**

The sheet shows Pay, Receive, Gas, Minimum Received, Price Impact, Route, Slippage, Spender, and an expandable calldata section. After confirmation, keep the same sheet mounted and animate from summary content to `TransactionTimeline` using `AnimatedSwitcher`.

- [ ] **Step 6: Verify and commit**

```bash
flutter analyze
flutter test test/features/trade/trade_executor_test.dart test/features/trade/confirmation_sheet_test.dart
git add apps/mobile/lib/core/security apps/mobile/lib/features/trade apps/mobile/test/features/trade
git commit -m "feat: execute biometric-gated on-chain swaps"
```

---

### Task 10: Persist Pending Transactions and Refresh Portfolio After Restart

**Files:**
- Create: `apps/mobile/lib/features/trade/domain/pending_transaction.dart`
- Create: `apps/mobile/lib/features/trade/data/pending_transaction_store.dart`
- Create: `apps/mobile/lib/features/trade/application/transaction_tracker.dart`
- Create: `apps/mobile/lib/features/trade/application/error_translator.dart`
- Modify: `apps/mobile/lib/main.dart`
- Modify: portfolio and trade controllers
- Test: `apps/mobile/test/features/trade/transaction_tracker_test.dart`
- Test: `apps/mobile/test/features/trade/error_translator_test.dart`

**Interfaces:**
- Produces: restart-safe tracking keyed by Tx Hash; `TradeFailure` categories used by UI.

- [ ] **Step 1: Write persistence and recovery tests**

Store a submitted Tx Hash, recreate the tracker with a fake receipt source, emit one pending poll and one confirmed receipt, and assert the store entry is removed only after confirmation. Test that an RPC timeout preserves the pending item.

- [ ] **Step 2: Implement a non-sensitive pending store**

Use `SharedPreferencesAsync` for JSON records containing only Tx Hash, wallet address, pair ID, stage, and created timestamp. Do not store calldata, signatures, auth tokens, or private keys.

- [ ] **Step 3: Implement receipt polling**

Poll at 2, 3, 5, 8, 13, and then 20-second intervals with a 10-minute UI threshold. After 10 minutes, show “Still pending” while continuing low-frequency checks. On receipt success, invalidate market, quote, and portfolio providers.

- [ ] **Step 4: Translate technical failures**

Map provider/RPC errors to these categories: `insufficientGas`, `insufficientLiquidity`, `quoteExpired`, `userRejected`, `approvalFailed`, `swapReverted`, `networkUnavailable`, `unknown`. Preserve the original message only inside an expandable technical-details field.

- [ ] **Step 5: Restore tracking during app startup**

After `ProviderScope` initialization and auth restoration, load pending transactions for the active address and resume receipt tracking before rendering Portfolio history.

- [ ] **Step 6: Verify and commit**

```bash
flutter analyze
flutter test test/features/trade/transaction_tracker_test.dart test/features/trade/error_translator_test.dart
git add apps/mobile/lib apps/mobile/test/features/trade
git commit -m "feat: recover pending transactions across restarts"
```

---

### Task 11: Add Deposit, Withdraw, History, and Settings

**Files:**
- Create: `apps/mobile/lib/features/portfolio/presentation/deposit_sheet.dart`
- Create: `apps/mobile/lib/features/portfolio/presentation/withdraw_screen.dart`
- Create: `apps/mobile/lib/features/portfolio/domain/activity_item.dart`
- Create: `apps/mobile/lib/features/portfolio/application/activity_controller.dart`
- Create: `apps/mobile/lib/features/settings/presentation/settings_screen.dart`
- Create: `apps/mobile/lib/features/settings/application/settings_controller.dart`
- Modify: `apps/mobile/lib/app/router.dart`
- Modify: `apps/mobile/lib/features/portfolio/presentation/portfolio_screen.dart`
- Test: `apps/mobile/test/features/portfolio/withdraw_screen_test.dart`
- Test: `apps/mobile/test/features/settings/settings_controller_test.dart`

**Interfaces:**
- Produces: EIP-681-style Base receive QR; exact-amount ETH/USDC withdrawal; merged local swap and on-chain transfer history; theme/currency settings.

- [ ] **Step 1: Write withdrawal validation tests**

Assert invalid EVM addresses, zero amount, amount greater than balance, and USDC amount exceeding six decimals are rejected. Assert a valid address and amount enables confirmation.

- [ ] **Step 2: Build Deposit**

Display the active address, Base network badge, copy action, and QR using `ethereum:<address>@8453`. Add a warning that sending assets on another network can make them inaccessible in the app.

- [ ] **Step 3: Build Withdraw**

Use the same biometric gate, confirmation sheet, signing service, timeline, and pending store as Swap. For USDC, encode `transfer(to, amount)`; for ETH, create a value transfer. Do not create a parallel transaction implementation.

- [ ] **Step 4: Build unified activity history**

Merge pending store records, confirmed app swaps, and recent transfer receipts into `ActivityItem` values sorted by timestamp. Each row shows type, pair/token, amount, status, shortened Tx Hash, and a Base explorer deep link.

- [ ] **Step 5: Build settings**

Support light/dark/system appearance, USD display currency, biometric toggle, wallet address details, risk disclosures, and logout. Persist non-sensitive settings through `SharedPreferencesAsync`.

- [ ] **Step 6: Verify and commit**

```bash
flutter analyze
flutter test test/features/portfolio test/features/settings
git add apps/mobile/lib/features/portfolio apps/mobile/lib/features/settings apps/mobile/lib/app/router.dart apps/mobile/test
git commit -m "feat: add funding, withdrawals, history, and settings"
```

---

### Task 12: Visual Regression, End-to-End Verification, Security Review, and Demo

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
- Produces: reproducible screenshots, mocked end-to-end flow, release checklist, two-minute demo script.

- [ ] **Step 1: Add deterministic golden tests**

Render Market, Pair Detail, Trade confirmation, Transaction timeline, and Portfolio at `390x844` in both light and dark modes. Use Flutter’s built-in `matchesGoldenFile` API rather than the discontinued `golden_toolkit` package.

- [ ] **Step 2: Add an integration test using fakes**

The test must execute:

```text
restore session → open ETH/USDC → enter 100 USDC → receive quote
→ approve → swap → confirm receipt → portfolio total changes
```

Override Riverpod gateways with fakes; do not call production providers in CI.

- [ ] **Step 3: Add manual Base mainnet verification**

Document a controlled low-value verification using a dedicated test wallet and a small USDC amount. Require the operator to compare the confirmation sheet’s sell amount, spender, destination, chain ID, minimum received, and Gas estimate against the normalized quote before signing.

- [ ] **Step 4: Write architecture and security documentation**

`docs/architecture.md` must explain feature boundaries, API contracts, quote expiry, transaction state transitions, and why the Worker exists. `docs/security.md` must document key lifecycle, biometric limitations, provider trust, API-key protection, exact approvals, allowlists, logging redaction, and the non-custodial boundary.

- [ ] **Step 5: Add release CI gates**

CI must run Flutter analyze/tests/goldens, Worker typecheck/tests, scan committed files for strings matching private-key patterns and configured API secret names, and fail when generated Dart files are stale.

- [ ] **Step 6: Create the two-minute portfolio demo**

`docs/demo-script.md` sequence:

1. Show polished Market and ETH detail animation.
2. Sign in and show the recovered embedded wallet address.
3. Enter a 100 USDC Swap and expand Route, Slippage, Gas, and Price Impact.
4. Confirm through biometrics.
5. Show Approve and Swap stages without leaving the app.
6. Show Tx Hash, Base explorer link, updated holdings, and PnL.
7. Finish on the architecture diagram and automated test summary.

- [ ] **Step 7: Run full verification and commit**

```bash
cd apps/mobile
flutter pub get
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
git add .
git commit -m "test: harden Flutter DEX release flow"
```

Expected: every command passes and no secret or private-key material appears in Git history.

---

## Plan Self-Review

### Spec coverage

- Three-tab navigation: Tasks 2, 4, 8, 11.
- Apple-inspired visual quality and motion: Tasks 2, 4, 9, 12.
- Live markets and candles: Task 5.
- Embedded recoverable wallet: Task 6.
- Base balances and portfolio: Task 7.
- DEX quotes, Slippage, Gas, Route, Price Impact: Task 8.
- Approve, biometric confirmation, signing, broadcast: Task 9.
- Transaction timeline and restart recovery: Task 10.
- Deposit, Withdraw, History, Settings: Task 11.
- Unit, widget, integration, and visual regression tests: Tasks 1–12, especially Task 12.
- Security boundaries and provider-key protection: Tasks 5, 6, 9, 10, 12.

### Type consistency

- `TokenInfo`, `MarketPair`, `Candle`, `Holding`, `SwapQuote`, and `TransactionStage` originate in Task 3 and are consumed without renaming.
- `EmbeddedWalletGateway` originates in Task 6 and is consumed by `TransactionSigner` in Task 9.
- `EvmClient` originates in Task 7 and is consumed by Tasks 9–11.
- The Worker returns decimal values as strings and integer token amounts as strings; Flutter parses them into `Decimal` and `BigInt` respectively.

### Scope integrity

The plan implements one chain, one curated pair, one embedded-wallet provider, one market-data provider, and one swap provider. It does not include multi-chain support, bridges, order books, limit orders, leverage, AI agents, NFT features, a dApp browser, custom RPC management, or a platform token.
