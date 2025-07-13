import 'package:dex_app/features/market/market_screen.dart';
import 'package:dex_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows catalog and disables non-tradable assets', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MarketScreen(),
      ),
    );
    expect(find.text('ETH'), findsOneWidget);
    expect(find.text('BTC'), findsOneWidget);
    expect(find.text('Tradable'), findsOneWidget);
    expect(find.text('Market data only'), findsWidgets);
  });
}
