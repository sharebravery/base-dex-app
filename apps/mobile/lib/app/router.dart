import 'package:dex_app/app/app_shell.dart';
import 'package:dex_app/core/web3/base_tokens.dart';
import 'package:dex_app/features/auth/auth_providers.dart';
import 'package:dex_app/features/auth/sign_in_screen.dart';
import 'package:dex_app/features/market/market_models.dart';
import 'package:dex_app/features/market/market_screen.dart';
import 'package:dex_app/features/market/pair_detail_screen.dart';
import 'package:dex_app/features/portfolio/activity_screen.dart';
import 'package:dex_app/features/portfolio/deposit_sheet.dart';
import 'package:dex_app/features/portfolio/portfolio_screen.dart';
import 'package:dex_app/features/portfolio/withdraw_controller.dart';
import 'package:dex_app/features/portfolio/withdraw_screen.dart';
import 'package:dex_app/features/settings/settings_providers.dart';
import 'package:dex_app/features/settings/settings_screen.dart';
import 'package:dex_app/features/trade/trade_providers.dart';
import 'package:dex_app/features/trade/trade_screen_wired.dart';
import 'package:dex_app/l10n/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
  initialLocation: '/market',
  routes: [
    GoRoute(
      path: '/sign-in',
      builder: (context, state) => Consumer(
        builder: (context, ref, child) => SignInScreen(
          onLogin: (method) async {
            final session =
                await ref.read(authControllerProvider).login(method);
            ref.read(activeWalletSessionProvider.notifier).state = session;
            if (context.mounted) context.go('/market');
          },
        ),
      ),
    ),
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
                      orElse: () => MarketAsset.fixtures.first,
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
              builder: (context, state) => const TradeScreenWired(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/portfolio',
              builder: (context, state) => Consumer(
                builder: (context, ref, _) {
                  final session = ref.watch(activeWalletSessionProvider);
                  if (session == null) return const _UnauthedPortfolio();
                  return PortfolioRouteScreen(address: session.address);
                },
              ),
              routes: [
                GoRoute(
                  path: 'deposit',
                  builder: (context, state) => const _DepositRoute(),
                ),
                GoRoute(
                  path: 'withdraw',
                  builder: (context, state) => const _WithdrawRoute(),
                ),
                GoRoute(
                  path: 'activity',
                  builder: (context, state) => const ActivityScreen(),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => Consumer(
                builder: (context, ref, _) {
                  final controller = ref.watch(settingsControllerProvider);
                  final session = ref.watch(activeWalletSessionProvider);
                  return SettingsScreen(
                    controller: controller,
                    walletAddress: session?.address ?? 'not-signed-in',
                    onLogout: () async {},
                  );
                },
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);

class _UnauthedPortfolio extends StatelessWidget {
  const _UnauthedPortfolio();

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: Text(
              'Sign in to view portfolio',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
      );
}

class _DepositRoute extends ConsumerWidget {
  const _DepositRoute();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(activeWalletSessionProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.deposit)),
      body: session == null
          ? const SizedBox()
          : DepositSheet(address: session.address),
    );
  }
}

class _WithdrawRoute extends ConsumerWidget {
  const _WithdrawRoute();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(activeWalletSessionProvider);
    if (session == null) {
      return Scaffold(appBar: AppBar(title: Text(context.l10n.withdraw)));
    }
    final store = ref.watch(pendingTransactionStoreProvider);
    final biometric = ref.watch(biometricGateProvider);
    final transactions = ref.watch(transactionServiceProvider);
    final wallet = ref.watch(walletServiceProvider);
    final chain = ref.watch(chainGatewayProvider);
    return WithdrawScreen(
      controller: const WithdrawController(),
      biometric: biometric,
      transactions: transactions,
      wallet: wallet,
      chain: chain,
      store: store,
      walletAddress: session.address,
      token: BaseTokens.usdc,
      currentBalance: BigInt.zero,
    );
  }
}
