import 'package:dex_app/features/trade/trade_executor.dart';
import 'package:dex_app/features/trade/transaction_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_helper.dart';

void main() {
  testWidgets('timeline_confirmed_390x844_en_light', (tester) async {
    await pumpGolden(
      tester,
      child: const Scaffold(
        body: Padding(
          padding: EdgeInsets.all(24),
          child: TransactionTimeline(stage: TransactionStage.confirmed),
        ),
      ),
      size: GoldenSizes.phonePortrait,
      locale: const Locale('en'),
    );
    await expectLater(
      find.byType(TransactionTimeline),
      matchesGoldenFile('goldens/timeline_confirmed_390x844_en_light.png'),
    );
  });
}
