import 'package:dex_app/features/market/market_models.dart';
import 'package:dex_app/features/market/market_providers.dart';
import 'package:dex_app/features/market/market_repository.dart';
import 'package:dex_app/features/market/market_screen.dart';
import 'package:dex_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeMarketRepository implements MarketRepository {
  @override
  Future<List<MarketAsset>> getAssets() async => MarketAsset.fixtures;

  @override
  Future<Map<String, List<double>>> getSparklines() async => const {};

  @override
  Future<List<Candle>> getCandles({
    required String assetId,
    required String interval,
  }) async {
    return const [];
  }

  @override
  Future<List<RecentTrade>> getRecentTrades({
    required String assetId,
    int limit = 30,
  }) async =>
      const [];
}

void main() {
  testWidgets('renders the catalog, hero, and trending strips', (tester) async {
    // Use a taller viewport so the main list sits below the fold and both
    // the hero card and trending carousels are laid out.
    await tester.binding.setSurfaceSize(const Size(390, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          marketRepositoryProvider.overrideWithValue(_FakeMarketRepository()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const MarketScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // ETH and BTC appear at least once — in the trending carousel and the
    // filter-agnostic main list.
    expect(find.text('ETH'), findsWidgets);
    expect(find.text('BTC'), findsWidgets);
    // Hero card label survives localization.
    expect(find.text('MARKET OVERVIEW'), findsOneWidget);
    // Category filter chip label — proves the sticky header renders.
    expect(find.text('All'), findsOneWidget);
  });
}
