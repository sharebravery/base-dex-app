import 'package:dex_app/features/portfolio/deposit_sheet.dart';
import 'package:dex_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

const _address = '0x1111111111111111111111111111111111111111';

void main() {
  testWidgets('DepositSheet renders address, QR, and localized copy', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: DepositSheet(address: _address)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(_address), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('Deposit on Base'), findsOneWidget);
    expect(find.text('Copy address'), findsOneWidget);
  });
}
