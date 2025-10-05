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

void main() {
  testWidgets('renders Simplified Chinese navigation labels', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          marketRepositoryProvider.overrideWithValue(_FakeMarketRepository()),
        ],
        child: const DexApp(locale: Locale('zh')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('市场'), findsWidgets);
    expect(find.text('交易'), findsOneWidget);
    expect(find.text('资产'), findsOneWidget);
  });
}
