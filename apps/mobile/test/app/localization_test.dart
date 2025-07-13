import 'package:dex_app/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders Simplified Chinese navigation labels', (tester) async {
    await tester.pumpWidget(const DexApp(locale: Locale('zh')));
    await tester.pumpAndSettle();
    expect(find.text('市场'), findsWidgets);
    expect(find.text('交易'), findsOneWidget);
    expect(find.text('资产'), findsOneWidget);
  });
}
