import 'package:dex_app/features/market/market_models.dart';
import 'package:dex_app/features/market/market_providers.dart';
import 'package:dex_app/features/market/market_repository.dart';
import 'package:dex_app/features/trade/pending_transaction_store.dart';
import 'package:dex_app/features/trade/trade_providers.dart';
import 'package:dex_app/l10n/app_localizations.dart';
import 'package:dex_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

final class _FixtureMarketRepository implements MarketRepository {
  @override
  Future<List<MarketAsset>> getAssets() async => MarketAsset.fixtures;

  @override
  Future<Map<String, List<double>>> getSparklines() async => const {};

  @override
  Future<List<Candle>> getCandles({
    required String assetId,
    required String interval,
  }) async =>
      const [];

  @override
  Future<List<RecentTrade>> getRecentTrades({
    required String assetId,
    int limit = 30,
  }) async =>
      const [];
}

/// Deterministic golden harness. Pumps a [MaterialApp] wrapped in a
/// [ProviderScope] with fixture-backed data providers so widgets that read
/// riverpod don't blow up under `flutter test`.
Future<void> pumpGolden(
  WidgetTester tester, {
  required Widget child,
  required Size size,
  required Locale locale,
  Brightness brightness = Brightness.light,
  double textScale = 1.0,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  // In-memory pending-tx store so widgets that read
  // pendingTransactionStoreProvider (portfolio recent-activity, activity
  // screen) render deterministically under the golden harness.
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
  final pendingStore = PendingTransactionStore(SharedPreferencesAsync());

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        marketRepositoryProvider
            .overrideWithValue(_FixtureMarketRepository()),
        pendingTransactionStoreProvider.overrideWithValue(pendingStore),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: brightness == Brightness.dark
            ? AppTheme.dark()
            : AppTheme.light(),
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            devicePixelRatio: 1,
            textScaler: TextScaler.linear(textScale),
          ),
          child: child,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Standard sizes used across the golden matrix.
class GoldenSizes {
  static const phonePortrait = Size(390, 844);
  static const compactPhone = Size(320, 568);
}
