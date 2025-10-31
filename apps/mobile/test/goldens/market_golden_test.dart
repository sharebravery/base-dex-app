@Tags(['golden'])
library;

import 'package:dex_app/features/market/market_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_helper.dart';

void main() {
  testWidgets('market_390x844_en_light', (tester) async {
    await pumpGolden(
      tester,
      child: const MarketScreen(),
      size: GoldenSizes.phonePortrait,
      locale: const Locale('en'),
    );
    await expectLater(
      find.byType(MarketScreen),
      matchesGoldenFile('goldens/market_390x844_en_light.png'),
    );
  });

  testWidgets('market_390x844_zh_dark', (tester) async {
    await pumpGolden(
      tester,
      child: const MarketScreen(),
      size: GoldenSizes.phonePortrait,
      locale: const Locale('zh'),
      brightness: Brightness.dark,
    );
    await expectLater(
      find.byType(MarketScreen),
      matchesGoldenFile('goldens/market_390x844_zh_dark.png'),
    );
  });

  testWidgets('market_320x568_en_light', (tester) async {
    await pumpGolden(
      tester,
      child: const MarketScreen(),
      size: GoldenSizes.compactPhone,
      locale: const Locale('en'),
    );
    await expectLater(
      find.byType(MarketScreen),
      matchesGoldenFile('goldens/market_320x568_en_light.png'),
    );
  });
}
