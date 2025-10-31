@Tags(['golden'])
library;

import 'package:dex_app/core/web3/base_tokens.dart';
import 'package:dex_app/features/trade/confirmation_sheet.dart';
import 'package:dex_app/features/trade/trade_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_helper.dart';

SwapQuote _quote() {
  return SwapQuote(
    sellAmount: BigInt.from(1000000),
    buyAmount: BigInt.from(300),
    minBuyAmount: BigInt.from(298),
    networkFee: BigInt.one,
    allowanceTarget: '0x0000000000000000000000000000000000000001',
    transactionTo: '0x0000000000000000000000000000000000000002',
    transactionData: '0x1234',
    transactionValue: BigInt.zero,
    gas: BigInt.from(220000),
    gasPrice: BigInt.one,
    routeLabels: const ['Uniswap_V3'],
    fetchedAt: DateTime.utc(2100),
    validFor: const Duration(minutes: 5),
  );
}

Widget _sheet() => Scaffold(
      body: SingleChildScrollView(
        child: ConfirmationSheet(
          quote: _quote(),
          sellToken: BaseTokens.usdc,
          currentAllowance: BigInt.zero,
          onConfirm: () {},
        ),
      ),
    );

void main() {
  testWidgets('confirmation_390x844_en_light', (tester) async {
    await pumpGolden(
      tester,
      child: _sheet(),
      size: GoldenSizes.phonePortrait,
      locale: const Locale('en'),
    );
    await expectLater(
      find.byType(ConfirmationSheet),
      matchesGoldenFile('goldens/confirmation_390x844_en_light.png'),
    );
  });

  testWidgets('confirmation_390x844_zh_dark', (tester) async {
    await pumpGolden(
      tester,
      child: _sheet(),
      size: GoldenSizes.phonePortrait,
      locale: const Locale('zh'),
      brightness: Brightness.dark,
    );
    await expectLater(
      find.byType(ConfirmationSheet),
      matchesGoldenFile('goldens/confirmation_390x844_zh_dark.png'),
    );
  });

  testWidgets('confirmation_390x844_text2x_en_light', (tester) async {
    await pumpGolden(
      tester,
      child: _sheet(),
      size: GoldenSizes.phonePortrait,
      locale: const Locale('en'),
      textScale: 2.0,
    );
    await expectLater(
      find.byType(ConfirmationSheet),
      matchesGoldenFile('goldens/confirmation_390x844_text2x_en_light.png'),
    );
  });
}
