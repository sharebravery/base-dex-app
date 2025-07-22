import 'package:dex_app/app/app_shell.dart';
import 'package:dex_app/features/market/market_models.dart';
import 'package:dex_app/features/market/market_screen.dart';
import 'package:dex_app/features/market/pair_detail_screen.dart';
import 'package:dex_app/l10n/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

Widget _placeholder(BuildContext context, String label) => Scaffold(
      appBar: AppBar(title: Text(label)),
      body: SafeArea(child: Center(child: Text(label))),
    );

final appRouter = GoRouter(
  initialLocation: '/market',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppShell(navigationShell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/market',
              builder: (context, state) => const MarketScreen(),
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
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/trade',
              builder: (context, state) =>
                  _placeholder(context, context.l10n.tradePlaceholder),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/portfolio',
              builder: (context, state) =>
                  _placeholder(context, context.l10n.portfolioPlaceholder),
            ),
          ],
        ),
      ],
    ),
  ],
);
