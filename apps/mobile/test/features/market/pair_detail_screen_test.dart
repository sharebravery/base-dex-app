import 'package:dex_app/features/market/market_models.dart';
import 'package:dex_app/features/market/pair_detail_screen.dart';
import 'package:dex_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ETH detail enables Swap', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PairDetailScreen(asset: MarketAsset.fixtures.first),
      ),
    );
    expect(find.text('ETH / USDC'), findsOneWidget);
    expect(find.text('Swap'), findsOneWidget);
  });
}
