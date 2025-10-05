import 'package:dex_app/app/app.dart';
import 'package:dex_app/features/market/market_models.dart';
import 'package:dex_app/features/market/market_providers.dart';
import 'package:dex_app/features/market/market_repository.dart';
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
  }) async =>
      const [];
  @override
  Future<List<RecentTrade>> getRecentTrades({
    required String assetId,
    int limit = 30,
  }) async =>
      const [];
}

Widget _app({Locale? locale}) {
  return ProviderScope(
    overrides: [
      marketRepositoryProvider.overrideWithValue(_FakeMarketRepository()),
    ],
    child: DexApp(locale: locale),
  );
}

void main() {
  Future<void> setSize(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('compact width uses NavigationBar', (tester) async {
    await setSize(tester, const Size(390, 844));
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('medium width uses NavigationRail', (tester) async {
    await setSize(tester, const Size(768, 1024));
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
