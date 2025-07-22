import 'package:dex_app/features/market/market_models.dart';
import 'package:dex_app/features/market/pair_detail_screen.dart';
import 'package:dex_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('route /market/:assetId renders PairDetailScreen', (tester) async {
    final router = GoRouter(
      initialLocation: '/market/ethereum',
      routes: [
        GoRoute(
          path: '/market',
          builder: (context, state) => const SizedBox(),
          routes: [
            GoRoute(
              path: ':assetId',
              builder: (context, state) {
                final assetId = state.pathParameters['assetId']!;
                final asset = MarketAsset.fixtures.firstWhere(
                  (asset) => asset.id == assetId,
                );
                return PairDetailScreen(asset: asset);
              },
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ETH / USDC'), findsOneWidget);
  });
}
