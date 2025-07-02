# Flutter DEX Phase 1 — Foundation and Market Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Track each checkbox and review each task before continuing.

**Goal:** Produce a tested Flutter/Worker workspace with localization, responsive navigation, a polished static Market experience, and normalized live market/OHLC data.

**Architecture:** The Flutter app uses `MaterialApp.router`, Riverpod, generated localization, and shallow feature folders. The Worker owns third-party market-provider JSON and exposes stable `/v1/markets` and `/v1/candles` contracts.

**Tech Stack:** Flutter, Riverpod, go_router, Dio, Decimal, Flutter gen-l10n, Hono, Zod, Vitest, Cloudflare Workers.

## Global Constraints

- Apply every constraint from `2026-07-15-flutter-dex-v1.md`.
- Phase 1 contains no real wallet, signing, database, or Swap execution.
- Mock fixtures must be deterministic.
- Non-ETH/USDC assets are market-data-only.
- No user-visible string may be hard-coded outside ARB files after Task 2.

---

## File Map

```text
apps/mobile/
├── l10n.yaml
├── lib/
│   ├── main.dart
│   ├── app/{app.dart,app_shell.dart,router.dart}
│   ├── core/{api_client.dart,app_config.dart,responsive.dart}
│   ├── l10n/{app_en.arb,app_zh.arb,l10n_extension.dart}
│   ├── theme/{app_colors.dart,app_spacing.dart,app_theme.dart}
│   └── features/market/
│       ├── market_controller.dart
│       ├── market_models.dart
│       ├── market_repository.dart
│       ├── market_screen.dart
│       ├── pair_detail_screen.dart
│       └── widgets/{candlestick_chart.dart,market_asset_tile.dart,sparkline_chart.dart}
└── test/
apps/api/
├── src/{env.ts,index.ts,market/client.ts,market/routes.ts,market/schema.ts}
└── test/{health.test.ts,market.test.ts}
```

---

### Task 1: Bootstrap Workspace, Environments, and CI

**Files:**
- Create: `apps/mobile/lib/core/app_config.dart`
- Modify: `apps/mobile/lib/main.dart`
- Create: `apps/mobile/test/app_smoke_test.dart`
- Create: `apps/api/package.json`
- Create: `apps/api/tsconfig.json`
- Create: `apps/api/wrangler.jsonc`
- Create: `apps/api/src/env.ts`
- Create: `apps/api/src/index.ts`
- Create: `apps/api/test/health.test.ts`
- Create: `.github/workflows/ci.yml`

**Interfaces:**
- Consumes: no project interfaces.
- Produces: `AppEnvironment`, `AppConfig.fromEnvironment()`, Hono `app`, `GET /health`.

- [ ] **Step 1: Write failing Flutter and Worker smoke tests**

Create `apps/mobile/test/app_smoke_test.dart`:

```dart
import 'package:dex_app/core/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mock config parses valid compile-time values', () {
    final config = AppConfig.fromValues(
      environment: 'mock',
      apiBaseUrl: 'http://127.0.0.1:8787',
      baseRpcUrl: 'https://mainnet.base.org',
      web3AuthClientId: 'test-client',
    );

    expect(config.environment, AppEnvironment.mock);
    expect(config.apiBaseUrl.host, '127.0.0.1');
    expect(config.baseRpcUrl.host, 'mainnet.base.org');
  });
}
```

Create `apps/api/test/health.test.ts`:

```ts
import { describe, expect, it } from 'vitest';
import app from '../src/index';

describe('GET /health', () => {
  it('returns a stable health contract', async () => {
    const response = await app.request('/health');
    expect(response.status).toBe(200);
    expect(await response.json()).toEqual({ status: 'ok' });
  });
});
```

- [ ] **Step 2: Run tests and verify red state**

```bash
cd apps/mobile
flutter test test/app_smoke_test.dart
cd ../api
npm test
```

Expected: Flutter fails because `AppConfig` does not exist; Worker test fails because the package and route do not exist.

- [ ] **Step 3: Create projects and install dependencies with lockfiles**

```bash
mkdir -p apps
flutter create --org com.cloudysky --project-name dex_app apps/mobile
cd apps/mobile
flutter pub add flutter_riverpod riverpod_annotation hooks_riverpod flutter_hooks go_router dio decimal intl freezed_annotation json_annotation fl_chart flutter_svg
flutter pub add --dev build_runner freezed json_serializable riverpod_generator riverpod_lint custom_lint mocktail
cd ../..
mkdir -p apps/api/src apps/api/test
cd apps/api
npm init -y
npm config set save-exact true
npm install hono zod
npm install --save-dev typescript vitest wrangler @cloudflare/workers-types
```

Edit `apps/mobile/pubspec.yaml` so the SDK localization dependency exists:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
```

- [ ] **Step 4: Implement typed Flutter configuration**

Create `apps/mobile/lib/core/app_config.dart`:

```dart
enum AppEnvironment { mock, staging, production }

final class AppConfig {
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.baseRpcUrl,
    required this.web3AuthClientId,
  });

  factory AppConfig.fromEnvironment() => AppConfig.fromValues(
        environment: const String.fromEnvironment(
          'APP_ENV',
          defaultValue: 'mock',
        ),
        apiBaseUrl: const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'http://127.0.0.1:8787',
        ),
        baseRpcUrl: const String.fromEnvironment(
          'BASE_RPC_URL',
          defaultValue: 'https://mainnet.base.org',
        ),
        web3AuthClientId: const String.fromEnvironment(
          'WEB3AUTH_CLIENT_ID',
          defaultValue: 'mock-client',
        ),
      );

  factory AppConfig.fromValues({
    required String environment,
    required String apiBaseUrl,
    required String baseRpcUrl,
    required String web3AuthClientId,
  }) {
    final parsedEnvironment = AppEnvironment.values.where(
      (value) => value.name == environment,
    );
    if (parsedEnvironment.length != 1) {
      throw ArgumentError.value(environment, 'environment');
    }

    final apiUri = Uri.tryParse(apiBaseUrl);
    final rpcUri = Uri.tryParse(baseRpcUrl);
    if (apiUri == null || !apiUri.hasScheme) {
      throw ArgumentError.value(apiBaseUrl, 'apiBaseUrl');
    }
    if (rpcUri == null || !rpcUri.hasScheme) {
      throw ArgumentError.value(baseRpcUrl, 'baseRpcUrl');
    }
    if (web3AuthClientId.trim().isEmpty) {
      throw ArgumentError.value(web3AuthClientId, 'web3AuthClientId');
    }

    return AppConfig(
      environment: parsedEnvironment.single,
      apiBaseUrl: apiUri,
      baseRpcUrl: rpcUri,
      web3AuthClientId: web3AuthClientId,
    );
  }

  final AppEnvironment environment;
  final Uri apiBaseUrl;
  final Uri baseRpcUrl;
  final String web3AuthClientId;
}
```

Replace `apps/mobile/lib/main.dart`:

```dart
import 'package:dex_app/core/app_config.dart';
import 'package:flutter/widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.fromEnvironment();
}
```

- [ ] **Step 5: Implement Worker entry point and validation types**

Configure `apps/api/package.json` through npm so the exact versions resolved by `npm install --save-exact` are recorded rather than copied from this plan:

```bash
cd apps/api
npm pkg set name=dex-api private=true type=module
npm pkg set scripts.dev="wrangler dev"
npm pkg set scripts.deploy="wrangler deploy"
npm pkg set scripts.test="vitest run"
npm pkg set scripts.typecheck="tsc --noEmit"
```

Expected: `package.json` contains exact dependency versions because Step 3 enabled `save-exact`, and `package-lock.json` exists.

Create `apps/api/tsconfig.json`:

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "lib": ["ES2022", "WebWorker"],
    "strict": true,
    "noEmit": true,
    "types": ["@cloudflare/workers-types"]
  },
  "include": ["src", "test"]
}
```

Create `apps/api/src/env.ts`:

```ts
export type Bindings = {
  APP_ENV: 'mock' | 'staging' | 'production';
  MARKET_API_BASE_URL: string;
  MARKET_API_KEY?: string;
};
```

Create `apps/api/src/index.ts`:

```ts
import { Hono } from 'hono';
import type { Bindings } from './env';

const app = new Hono<{ Bindings: Bindings }>();

app.get('/health', (context) => context.json({ status: 'ok' }));

export default app;
```

Create `apps/api/wrangler.jsonc`:

```jsonc
{
  "$schema": "node_modules/wrangler/config-schema.json",
  "name": "dex-api",
  "main": "src/index.ts",
  "compatibility_date": "2026-07-15",
  "compatibility_flags": ["nodejs_compat"],
  "vars": {
    "APP_ENV": "mock",
    "MARKET_API_BASE_URL": "https://api.coingecko.com/api/v3"
  }
}
```

- [ ] **Step 6: Add CI and verify green state**

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

Run:

```bash
cd apps/mobile
flutter test test/app_smoke_test.dart
flutter analyze
cd ../api
npm ci
npm run typecheck
npm test
```

Expected: all commands pass.

- [ ] **Step 7: Commit**

```bash
git add apps .github
git commit -m "chore: bootstrap Flutter DEX workspace"
```

---

### Task 2: Build Theme, Localization, Routing, and Responsive Shell

**Files:**
- Create: `apps/mobile/l10n.yaml`
- Create: `apps/mobile/lib/l10n/app_en.arb`
- Create: `apps/mobile/lib/l10n/app_zh.arb`
- Create: `apps/mobile/lib/l10n/l10n_extension.dart`
- Create: `apps/mobile/lib/theme/app_colors.dart`
- Create: `apps/mobile/lib/theme/app_spacing.dart`
- Create: `apps/mobile/lib/theme/app_theme.dart`
- Create: `apps/mobile/lib/core/responsive.dart`
- Create: `apps/mobile/lib/app/router.dart`
- Create: `apps/mobile/lib/app/app_shell.dart`
- Create: `apps/mobile/lib/app/app.dart`
- Modify: `apps/mobile/lib/main.dart`
- Test: `apps/mobile/test/app/localization_test.dart`
- Test: `apps/mobile/test/app/responsive_shell_test.dart`

**Interfaces:**
- Consumes: `AppConfig` from Task 1.
- Produces: `WindowClass`, `windowClassForWidth()`, `appRouter`, `DexApp`, routes `/market`, `/trade`, `/portfolio`.

- [ ] **Step 1: Write localization and responsive tests**

Create `apps/mobile/test/app/localization_test.dart`:

```dart
import 'package:dex_app/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders Simplified Chinese navigation labels', (tester) async {
    await tester.pumpWidget(const DexApp(locale: Locale('zh')));
    await tester.pumpAndSettle();
    expect(find.text('市场'), findsOneWidget);
    expect(find.text('交易'), findsOneWidget);
    expect(find.text('资产'), findsOneWidget);
  });
}
```

Create `apps/mobile/test/app/responsive_shell_test.dart`:

```dart
import 'package:dex_app/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> setSize(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('compact width uses NavigationBar', (tester) async {
    await setSize(tester, const Size(390, 844));
    await tester.pumpWidget(const DexApp());
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('medium width uses NavigationRail', (tester) async {
    await setSize(tester, const Size(768, 1024));
    await tester.pumpWidget(const DexApp());
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
```

- [ ] **Step 2: Run tests and verify red state**

```bash
cd apps/mobile
flutter test test/app/localization_test.dart test/app/responsive_shell_test.dart
```

Expected: failures because `DexApp`, generated localization, and responsive shell do not exist.

- [ ] **Step 3: Add generated localization files**

Create `apps/mobile/l10n.yaml`:

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
nullable-getter: false
```

Add under the existing `flutter:` section in `pubspec.yaml`:

```yaml
  generate: true
```

Create `apps/mobile/lib/l10n/app_en.arb`:

```json
{
  "@@locale": "en",
  "market": "Market",
  "trade": "Trade",
  "portfolio": "Portfolio",
  "settings": "Settings",
  "marketPlaceholder": "Market overview",
  "tradePlaceholder": "ETH / USDC Swap",
  "portfolioPlaceholder": "Portfolio overview"
}
```

Create `apps/mobile/lib/l10n/app_zh.arb`:

```json
{
  "@@locale": "zh",
  "market": "市场",
  "trade": "交易",
  "portfolio": "资产",
  "settings": "设置",
  "marketPlaceholder": "市场概览",
  "tradePlaceholder": "ETH / USDC 兑换",
  "portfolioPlaceholder": "资产概览"
}
```

Create `apps/mobile/lib/l10n/l10n_extension.dart`:

```dart
import 'package:dex_app/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
```

- [ ] **Step 4: Implement responsive and theme primitives**

Create `apps/mobile/lib/core/responsive.dart`:

```dart
abstract final class AppBreakpoints {
  static const compact = 600.0;
  static const medium = 840.0;
}

enum WindowClass { compact, medium, expanded }

WindowClass windowClassForWidth(double width) {
  if (width < AppBreakpoints.compact) return WindowClass.compact;
  if (width < AppBreakpoints.medium) return WindowClass.medium;
  return WindowClass.expanded;
}
```

Create `apps/mobile/lib/theme/app_colors.dart`:

```dart
import 'package:flutter/material.dart';

abstract final class AppColors {
  static const accent = Color(0xFF5B5CF6);
  static const positive = Color(0xFF158F63);
  static const negative = Color(0xFFD94D5C);
  static const lightBackground = Color(0xFFF5F6F8);
  static const darkBackground = Color(0xFF0D0E11);
}
```

Create `apps/mobile/lib/theme/app_spacing.dart`:

```dart
abstract final class AppSpacing {
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const radius = 20.0;
}
```

Create `apps/mobile/lib/theme/app_theme.dart`:

```dart
import 'package:dex_app/theme/app_colors.dart';
import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: brightness,
      surface: dark ? const Color(0xFF17181C) : Colors.white,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          dark ? AppColors.darkBackground : AppColors.lightBackground,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Implement router and responsive shell**

Create `apps/mobile/lib/app/app_shell.dart`:

```dart
import 'package:dex_app/core/responsive.dart';
import 'package:dex_app/l10n/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final windowClass = windowClassForWidth(constraints.maxWidth);
        final destinations = [
          NavigationDestination(
            icon: const Icon(Icons.show_chart),
            label: context.l10n.market,
          ),
          NavigationDestination(
            icon: const Icon(Icons.swap_horiz),
            label: context.l10n.trade,
          ),
          NavigationDestination(
            icon: const Icon(Icons.pie_chart_outline),
            label: context.l10n.portfolio,
          ),
        ];

        if (windowClass == WindowClass.compact) {
          return Scaffold(
            body: navigationShell,
            bottomNavigationBar: NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              destinations: destinations,
              onDestinationSelected: navigationShell.goBranch,
            ),
          );
        }

        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: navigationShell.currentIndex,
                labelType: NavigationRailLabelType.all,
                destinations: [
                  for (final destination in destinations)
                    NavigationRailDestination(
                      icon: destination.icon,
                      label: Text(destination.label),
                    ),
                ],
                onDestinationSelected: navigationShell.goBranch,
              ),
              const VerticalDivider(width: 1),
              Expanded(child: navigationShell),
            ],
          ),
        );
      },
    );
  }
}
```

Create `apps/mobile/lib/app/router.dart`:

```dart
import 'package:dex_app/app/app_shell.dart';
import 'package:dex_app/l10n/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

Widget _placeholder(BuildContext context, String label) => Scaffold(
      appBar: AppBar(title: Text(label)),
      body: SafeArea(child: Center(child: Text(label))),
    );

final appRouter = GoRouter(
  initialLocation: '/market',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppShell(navigationShell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/market',
              builder: (context, state) =>
                  _placeholder(context, context.l10n.marketPlaceholder),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/trade',
              builder: (context, state) =>
                  _placeholder(context, context.l10n.tradePlaceholder),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/portfolio',
              builder: (context, state) =>
                  _placeholder(context, context.l10n.portfolioPlaceholder),
            ),
          ],
        ),
      ],
    ),
  ],
);
```

Create `apps/mobile/lib/app/app.dart`:

```dart
import 'package:dex_app/app/router.dart';
import 'package:dex_app/l10n/app_localizations.dart';
import 'package:dex_app/theme/app_theme.dart';
import 'package:flutter/material.dart';

class DexApp extends StatelessWidget {
  const DexApp({super.key, this.locale});

  final Locale? locale;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: appRouter,
    );
  }
}
```

Replace `apps/mobile/lib/main.dart`:

```dart
import 'package:dex_app/app/app.dart';
import 'package:dex_app/core/app_config.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.fromEnvironment();
  runApp(const ProviderScope(child: DexApp()));
}
```

- [ ] **Step 6: Generate, verify, and commit**

```bash
cd apps/mobile
flutter gen-l10n
flutter analyze
flutter test test/app

git add apps/mobile
git commit -m "feat: add localized responsive app shell"
```

Expected: localization and responsive tests pass.

---

### Task 3: Define Curated Assets and Static Market Experience

**Files:**
- Create: `apps/mobile/lib/core/web3/base_tokens.dart`
- Create: `apps/mobile/lib/features/market/market_models.dart`
- Create: `apps/mobile/lib/features/market/market_controller.dart`
- Create: `apps/mobile/lib/features/market/market_screen.dart`
- Create: `apps/mobile/lib/features/market/pair_detail_screen.dart`
- Create: `apps/mobile/lib/features/market/widgets/market_asset_tile.dart`
- Create: `apps/mobile/lib/features/market/widgets/sparkline_chart.dart`
- Create: `apps/mobile/lib/features/market/widgets/candlestick_chart.dart`
- Modify: `apps/mobile/lib/app/router.dart`
- Modify: ARB files with Market strings
- Test: `apps/mobile/test/features/market/market_screen_test.dart`
- Test: `apps/mobile/test/features/market/pair_detail_screen_test.dart`

**Interfaces:**
- Consumes: routes and localization from Task 2.
- Produces: `TokenInfo`, `MarketAsset`, `Candle`, `MarketController`, route `/market/:assetId`.

- [ ] **Step 1: Write failing Market tests**

Create `apps/mobile/test/features/market/market_screen_test.dart`:

```dart
import 'package:dex_app/features/market/market_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows catalog and disables non-tradable assets', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MarketScreen()));
    expect(find.text('ETH'), findsOneWidget);
    expect(find.text('BTC'), findsOneWidget);
    expect(find.text('Tradable'), findsOneWidget);
    expect(find.text('Market data only'), findsWidgets);
  });
}
```

Create `apps/mobile/test/features/market/pair_detail_screen_test.dart`:

```dart
import 'package:dex_app/features/market/market_models.dart';
import 'package:dex_app/features/market/pair_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ETH detail enables Swap', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PairDetailScreen(asset: MarketAsset.fixtures.first),
      ),
    );
    expect(find.text('ETH / USDC'), findsOneWidget);
    expect(find.text('Swap'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run tests and verify red state**

```bash
flutter test test/features/market
```

Expected: compilation fails because Market files do not exist.

- [ ] **Step 3: Implement simple immutable models and deterministic fixtures**

Create `apps/mobile/lib/core/web3/base_tokens.dart`:

```dart
final class TokenInfo {
  const TokenInfo({
    required this.symbol,
    required this.name,
    required this.address,
    required this.decimals,
    required this.isNative,
  });

  final String symbol;
  final String name;
  final String address;
  final int decimals;
  final bool isNative;
}

abstract final class BaseTokens {
  static const eth = TokenInfo(
    symbol: 'ETH',
    name: 'Ether',
    address: '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE',
    decimals: 18,
    isNative: true,
  );
  static const usdc = TokenInfo(
    symbol: 'USDC',
    name: 'USD Coin',
    address: '0x833589fCD6eDb6E08f4c7C32D4f71b54bDa02913',
    decimals: 6,
    isNative: false,
  );
}
```

Create `apps/mobile/lib/features/market/market_models.dart`:

```dart
import 'package:decimal/decimal.dart';

final class Candle {
  const Candle({
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });

  final DateTime timestamp;
  final Decimal open;
  final Decimal high;
  final Decimal low;
  final Decimal close;
}

final class MarketAsset {
  const MarketAsset({
    required this.id,
    required this.symbol,
    required this.name,
    required this.priceUsd,
    required this.change24hPercent,
    required this.tradable,
  });

  final String id;
  final String symbol;
  final String name;
  final Decimal priceUsd;
  final Decimal change24hPercent;
  final bool tradable;

  static final fixtures = [
    MarketAsset(
      id: 'ethereum',
      symbol: 'ETH',
      name: 'Ethereum',
      priceUsd: Decimal.parse('3240.12'),
      change24hPercent: Decimal.parse('2.41'),
      tradable: true,
    ),
    MarketAsset(
      id: 'bitcoin',
      symbol: 'BTC',
      name: 'Bitcoin',
      priceUsd: Decimal.parse('97500.00'),
      change24hPercent: Decimal.parse('-0.82'),
      tradable: false,
    ),
    MarketAsset(
      id: 'solana',
      symbol: 'SOL',
      name: 'Solana',
      priceUsd: Decimal.parse('188.40'),
      change24hPercent: Decimal.parse('1.12'),
      tradable: false,
    ),
  ];
}
```

Create `apps/mobile/lib/features/market/market_controller.dart`:

```dart
import 'package:dex_app/features/market/market_models.dart';

final class MarketController {
  const MarketController();

  List<MarketAsset> loadFixtures() => List.unmodifiable(MarketAsset.fixtures);
}
```

- [ ] **Step 4: Implement static Market and detail screens**

Create `apps/mobile/lib/features/market/widgets/market_asset_tile.dart`:

```dart
import 'package:dex_app/features/market/market_models.dart';
import 'package:flutter/material.dart';

class MarketAssetTile extends StatelessWidget {
  const MarketAssetTile({required this.asset, this.onTap, super.key});

  final MarketAsset asset;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(asset.symbol),
      subtitle: Text(asset.tradable ? 'Tradable' : 'Market data only'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('\$${asset.priceUsd.toString()}'),
          Text('${asset.change24hPercent}%'),
        ],
      ),
    );
  }
}
```

Create `apps/mobile/lib/features/market/market_screen.dart`:

```dart
import 'package:dex_app/features/market/market_controller.dart';
import 'package:dex_app/features/market/widgets/market_asset_tile.dart';
import 'package:flutter/material.dart';

class MarketScreen extends StatelessWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final assets = const MarketController().loadFixtures();
    return Scaffold(
      appBar: AppBar(title: const Text('Market')),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: assets.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) => Card(
            child: MarketAssetTile(asset: assets[index]),
          ),
        ),
      ),
    );
  }
}
```

Create `apps/mobile/lib/features/market/pair_detail_screen.dart`:

```dart
import 'package:dex_app/features/market/market_models.dart';
import 'package:flutter/material.dart';

class PairDetailScreen extends StatelessWidget {
  const PairDetailScreen({required this.asset, super.key});

  final MarketAsset asset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(asset.tradable ? '${asset.symbol} / USDC' : asset.symbol),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('\$${asset.priceUsd}', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 16),
              const Expanded(child: Card(child: Center(child: Text('Chart')))),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: asset.tradable ? () {} : null,
                child: Text(asset.tradable ? 'Swap' : 'Market data only'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

Create minimal chart files so later tasks have stable names:

```dart
// sparkline_chart.dart
import 'package:flutter/widgets.dart';
class SparklineChart extends StatelessWidget {
  const SparklineChart({required this.points, super.key});
  final List<double> points;
  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
```

```dart
// candlestick_chart.dart
import 'package:dex_app/features/market/market_models.dart';
import 'package:flutter/widgets.dart';
class CandlestickChart extends StatelessWidget {
  const CandlestickChart({required this.candles, super.key});
  final List<Candle> candles;
  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
```

- [ ] **Step 5: Replace Market route and verify**

In `app/router.dart`, replace the `/market` placeholder builder with:

```dart
builder: (context, state) => const MarketScreen(),
```

Run:

```bash
flutter analyze
flutter test test/features/market test/app
```

Expected: all tests pass.

- [ ] **Step 6: Commit**

```bash
git add apps/mobile
git commit -m "feat: add curated static market experience"
```

---

### Task 4: Add Real Market and OHLC Data

**Files:**
- Create: `apps/api/src/market/schema.ts`
- Create: `apps/api/src/market/client.ts`
- Create: `apps/api/src/market/routes.ts`
- Modify: `apps/api/src/index.ts`
- Create: `apps/api/test/market.test.ts`
- Create: `apps/mobile/lib/core/api_client.dart`
- Create: `apps/mobile/lib/features/market/market_repository.dart`
- Modify: `apps/mobile/lib/features/market/market_controller.dart`
- Modify: `apps/mobile/lib/features/market/market_models.dart`
- Test: `apps/mobile/test/features/market/market_repository_test.dart`

**Interfaces:**
- Consumes: `MarketAsset` and `Candle` from Task 3; Worker `Bindings` from Task 1.
- Produces: `GET /v1/markets`, `GET /v1/candles`, `MarketRepository.getAssets()`, `MarketRepository.getCandles()`.

- [ ] **Step 1: Write Worker contract tests**

Create `apps/api/test/market.test.ts`:

```ts
import { afterEach, describe, expect, it, vi } from 'vitest';
import app from '../src/index';

afterEach(() => vi.restoreAllMocks());

describe('market routes', () => {
  it('normalizes current market data', async () => {
    vi.spyOn(globalThis, 'fetch').mockResolvedValueOnce(
      new Response(JSON.stringify([
        {
          id: 'ethereum',
          symbol: 'eth',
          name: 'Ethereum',
          current_price: 3240.12,
          price_change_percentage_24h: 2.41,
          total_volume: 812000000
        }
      ]), { status: 200 }),
    );

    const response = await app.request('/v1/markets', {}, {
      APP_ENV: 'mock',
      MARKET_API_BASE_URL: 'https://example.test',
    });
    expect(response.status).toBe(200);
    expect(await response.json()).toEqual({
      assets: [{
        id: 'ethereum',
        symbol: 'ETH',
        name: 'Ethereum',
        priceUsd: '3240.12',
        change24hPercent: '2.41',
        volume24hUsd: '812000000',
        tradable: true
      }]
    });
  });
});
```

- [ ] **Step 2: Run Worker test and verify red state**

```bash
cd apps/api
npm test -- market.test.ts
```

Expected: 404 or missing route failure.

- [ ] **Step 3: Implement Zod provider normalization and routes**

Create `apps/api/src/market/schema.ts`:

```ts
import { z } from 'zod';

export const providerMarketSchema = z.object({
  id: z.string(),
  symbol: z.string(),
  name: z.string(),
  current_price: z.number().finite(),
  price_change_percentage_24h: z.number().finite().nullable(),
  total_volume: z.number().finite().nonnegative(),
});

export const providerMarketsSchema = z.array(providerMarketSchema);
```

Create `apps/api/src/market/client.ts`:

```ts
import type { Bindings } from '../env';
import { providerMarketsSchema } from './schema';

const catalog = new Map([
  ['ethereum', true],
  ['bitcoin', false],
  ['solana', false],
  ['usd-coin', false],
  ['aerodrome-finance', false],
  ['degen-base', false],
]);

export async function getMarkets(env: Bindings) {
  const ids = [...catalog.keys()].join(',');
  const url = new URL('/coins/markets', env.MARKET_API_BASE_URL);
  url.searchParams.set('vs_currency', 'usd');
  url.searchParams.set('ids', ids);
  url.searchParams.set('price_change_percentage', '24h');

  const response = await fetch(url, {
    headers: env.MARKET_API_KEY
      ? { 'x-cg-demo-api-key': env.MARKET_API_KEY }
      : undefined,
  });
  if (!response.ok) throw new Error(`market provider ${response.status}`);
  const parsed = providerMarketsSchema.parse(await response.json());

  return {
    assets: parsed.map((asset) => ({
      id: asset.id,
      symbol: asset.symbol.toUpperCase(),
      name: asset.name,
      priceUsd: String(asset.current_price),
      change24hPercent: String(asset.price_change_percentage_24h ?? 0),
      volume24hUsd: String(asset.total_volume),
      tradable: catalog.get(asset.id) === true,
    })),
  };
}
```

Create `apps/api/src/market/routes.ts`:

```ts
import { Hono } from 'hono';
import type { Bindings } from '../env';
import { getMarkets } from './client';

export const marketRoutes = new Hono<{ Bindings: Bindings }>();

marketRoutes.get('/markets', async (context) => {
  const result = await getMarkets(context.env);
  return context.json(result, 200, {
    'Cache-Control': 'public, max-age=10, stale-while-revalidate=20',
  });
});

marketRoutes.get('/candles', async (context) => {
  const assetId = context.req.query('assetId');
  const interval = context.req.query('interval');
  if (assetId !== 'ethereum' || !['1d', '7d', '30d'].includes(interval ?? '')) {
    return context.json({ error: 'unsupported_candle_request' }, 400);
  }
  return context.json({ candles: [] });
});
```

Modify `apps/api/src/index.ts`:

```ts
import { Hono } from 'hono';
import type { Bindings } from './env';
import { marketRoutes } from './market/routes';

const app = new Hono<{ Bindings: Bindings }>();
app.get('/health', (context) => context.json({ status: 'ok' }));
app.route('/v1', marketRoutes);
export default app;
```

- [ ] **Step 4: Write Flutter repository test**

Create `apps/mobile/test/features/market/market_repository_test.dart`:

```dart
import 'package:dex_app/features/market/market_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

void main() {
  test('parses decimal strings without double authority', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    final adapter = DioAdapter(dio: dio);
    adapter.onGet('/v1/markets', (server) {
      server.reply(200, {
        'assets': [
          {
            'id': 'ethereum',
            'symbol': 'ETH',
            'name': 'Ethereum',
            'priceUsd': '3240.12',
            'change24hPercent': '2.41',
            'volume24hUsd': '812000000',
            'tradable': true,
          }
        ]
      });
    });

    final assets = await ApiMarketRepository(dio).getAssets();
    expect(assets.single.priceUsd.toString(), '3240.12');
    expect(assets.single.tradable, isTrue);
  });
}
```

Add the test-only dependency:

```bash
flutter pub add --dev http_mock_adapter
```

- [ ] **Step 5: Implement Flutter API parsing**

Create `apps/mobile/lib/core/api_client.dart`:

```dart
import 'package:dio/dio.dart';

Dio createApiClient(Uri baseUrl) => Dio(
      BaseOptions(
        baseUrl: baseUrl.toString(),
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );
```

Replace `apps/mobile/lib/features/market/market_repository.dart`:

```dart
import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:dex_app/features/market/market_models.dart';

abstract interface class MarketRepository {
  Future<List<MarketAsset>> getAssets();
  Future<List<Candle>> getCandles({
    required String assetId,
    required String interval,
  });
}

final class ApiMarketRepository implements MarketRepository {
  ApiMarketRepository(this._dio);
  final Dio _dio;

  @override
  Future<List<MarketAsset>> getAssets() async {
    final response = await _dio.get<Map<String, Object?>>('/v1/markets');
    final rawAssets = response.data!['assets']! as List<Object?>;
    return rawAssets.map((raw) {
      final json = raw! as Map<String, Object?>;
      return MarketAsset(
        id: json['id']! as String,
        symbol: json['symbol']! as String,
        name: json['name']! as String,
        priceUsd: Decimal.parse(json['priceUsd']! as String),
        change24hPercent:
            Decimal.parse(json['change24hPercent']! as String),
        tradable: json['tradable']! as bool,
      );
    }).toList(growable: false);
  }

  @override
  Future<List<Candle>> getCandles({
    required String assetId,
    required String interval,
  }) async {
    final response = await _dio.get<Map<String, Object?>>(
      '/v1/candles',
      queryParameters: {'assetId': assetId, 'interval': interval},
    );
    final raw = response.data!['candles']! as List<Object?>;
    return raw.map((item) {
      final json = item! as Map<String, Object?>;
      return Candle(
        timestamp: DateTime.parse(json['timestamp']! as String),
        open: Decimal.parse(json['open']! as String),
        high: Decimal.parse(json['high']! as String),
        low: Decimal.parse(json['low']! as String),
        close: Decimal.parse(json['close']! as String),
      );
    }).toList(growable: false);
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
flutter test test/features/market test/app

git add apps
git commit -m "feat: connect normalized market data"
```

Expected: all Phase 1 tests pass.

---

## Phase 1 Checkpoint

Run the full phase verification:

```bash
cd apps/mobile
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
cd ../api
npm ci
npm run typecheck
npm test
```

Expected: status `0` for every command. Review the diff before starting Phase 2.
