@Tags(['golden'])
library;

import 'package:decimal/decimal.dart';
import 'package:dex_app/features/portfolio/portfolio_models.dart';
import 'package:dex_app/features/portfolio/portfolio_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_helper.dart';

PortfolioSnapshot _snapshot() {
  return PortfolioSnapshot.fromHoldings([
    Holding(
      symbol: 'ETH',
      rawBalance: BigInt.parse('1500000000000000000'),
      decimals: 18,
      priceUsd: Decimal.parse('3200'),
    ),
    Holding(
      symbol: 'USDC',
      rawBalance: BigInt.parse('2500000000'),
      decimals: 6,
      priceUsd: Decimal.one,
    ),
  ]);
}

void main() {
  testWidgets('portfolio_390x844_en_light', (tester) async {
    await pumpGolden(
      tester,
      child: PortfolioScreen(snapshot: _snapshot()),
      size: GoldenSizes.phonePortrait,
      locale: const Locale('en'),
    );
    await expectLater(
      find.byType(PortfolioScreen),
      matchesGoldenFile('goldens/portfolio_390x844_en_light.png'),
    );
  });

  testWidgets('portfolio_390x844_zh_dark', (tester) async {
    await pumpGolden(
      tester,
      child: PortfolioScreen(snapshot: _snapshot()),
      size: GoldenSizes.phonePortrait,
      locale: const Locale('zh'),
      brightness: Brightness.dark,
    );
    await expectLater(
      find.byType(PortfolioScreen),
      matchesGoldenFile('goldens/portfolio_390x844_zh_dark.png'),
    );
  });
}
