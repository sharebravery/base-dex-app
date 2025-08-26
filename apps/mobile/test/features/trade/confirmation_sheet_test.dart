import 'package:dex_app/core/web3/base_tokens.dart';
import 'package:dex_app/features/trade/confirmation_sheet.dart';
import 'package:dex_app/features/trade/trade_models.dart';
import 'package:dex_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

SwapQuote _quote({required BigInt sellAmount, String? allowanceTarget}) {
  return SwapQuote(
    sellAmount: sellAmount,
    buyAmount: BigInt.from(300),
    minBuyAmount: BigInt.from(298),
    networkFee: BigInt.one,
    allowanceTarget: allowanceTarget,
    transactionTo: '0x0000000000000000000000000000000000000002',
    transactionData: '0x1234',
    transactionValue: BigInt.zero,
    gas: BigInt.from(220000),
    gasPrice: BigInt.one,
    routeLabels: const ['Uniswap_V3'],
    fetchedAt: DateTime.now(),
    validFor: const Duration(minutes: 1),
  );
}

void main() {
  testWidgets(
      'USDC sell with allowance target renders Approve USDC and exact amount',
      (tester) async {
    final sellAmount = BigInt.from(1000000);
    final quote = _quote(
      sellAmount: sellAmount,
      allowanceTarget: '0x0000000000000000000000000000000000000001',
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ConfirmationSheet(
            quote: quote,
            sellToken: BaseTokens.usdc,
            currentAllowance: BigInt.zero,
            onConfirm: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Approve USDC'), findsOneWidget);
    expect(find.text(sellAmount.toString()), findsWidgets);
  });
}
