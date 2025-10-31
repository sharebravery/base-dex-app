@Tags(['golden'])
library;

import 'package:dex_app/features/portfolio/deposit_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_helper.dart';

void main() {
  testWidgets('deposit_390x844_en_light', (tester) async {
    await pumpGolden(
      tester,
      child: const Scaffold(
        body: DepositSheet(address: '0x1111111111111111111111111111111111111111'),
      ),
      size: GoldenSizes.phonePortrait,
      locale: const Locale('en'),
    );
    await expectLater(
      find.byType(DepositSheet),
      matchesGoldenFile('goldens/deposit_390x844_en_light.png'),
    );
  });
}
