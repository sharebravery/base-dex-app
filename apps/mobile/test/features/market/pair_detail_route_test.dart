import 'package:dex_app/app/app.dart';
import 'package:dex_app/app/router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('market detail route renders the pair screen', (tester) async {
    await tester.pumpWidget(const DexApp());
    await tester.pumpAndSettle();

    appRouter.go('/market/ethereum');
    await tester.pumpAndSettle();

    expect(find.text('ETH / USDC'), findsOneWidget);
  });
}
