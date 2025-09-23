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
  Future<List<Candle>> getCandles({
    required String assetId,
    required String interval,
  }) async {
    return const [];
  }
}

void main() {
  testWidgets('shows catalog and disables non-tradable assets', (tester) async {
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
    expect(find.text('ETH'), findsOneWidget);
    expect(find.text('BTC'), findsOneWidget);
    expect(find.text('Tradable'), findsOneWidget);
    expect(find.text('Market data only'), findsWidgets);
  });
}
