import 'package:decimal/decimal.dart';
import 'package:dex_app/core/widgets/glass_card.dart';
import 'package:dex_app/features/market/market_models.dart';
import 'package:dex_app/features/market/market_providers.dart';
import 'package:dex_app/features/portfolio/portfolio_models.dart';
import 'package:dex_app/features/portfolio/portfolio_providers.dart';
import 'package:dex_app/features/portfolio/widgets/allocation_donut.dart';
import 'package:dex_app/features/portfolio/widgets/holding_row.dart';
import 'package:dex_app/features/portfolio/widgets/portfolio_hero_card.dart';
import 'package:dex_app/features/portfolio/widgets/quick_actions_grid.dart';
import 'package:dex_app/features/portfolio/widgets/recent_activity_card.dart';
import 'package:dex_app/features/trade/pending_transaction.dart';
import 'package:dex_app/features/trade/trade_providers.dart';
import 'package:dex_app/l10n/l10n_extension.dart';
import 'package:dex_app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Snapshot renderer used inline (embedded) and by the routed screen.
///
/// The market-derived overlays (24h change, P&L trend) are optional so the
/// unit tests that pump this widget with a hand-built snapshot don't have
/// to wire up the market provider tree.
class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({required this.snapshot, super.key})
      : _embedded = false;
  const PortfolioScreen.embedded({required this.snapshot, super.key})
      : _embedded = true;

  final PortfolioSnapshot snapshot;
  final bool _embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Market data drives the hero pill + trend. Any failure here degrades
    // gracefully — the pill just disappears.
    final marketAsync = ref.watch(marketAssetsProvider);
    final sparklinesAsync = ref.watch(sparklinesProvider);
    final assets = marketAsync.asData?.value ?? const <MarketAsset>[];
    final sparklines =
        sparklinesAsync.asData?.value ?? const <String, List<double>>{};
    final change24h = _weightedChange24h(snapshot, assets);
    final trend = _synthesizeTrend(snapshot, assets, sparklines);

    final l10n = context.l10n;

    final body = CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          sliver: SliverToBoxAdapter(
            child: PortfolioHeroCard(
              snapshot: snapshot,
              change24hPercent: change24h,
              trend: trend,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          sliver: SliverToBoxAdapter(
            child: QuickActionsGrid(
              onDeposit: () => context.push('/portfolio/deposit'),
              onWithdraw: () => context.push('/portfolio/withdraw'),
              onSwap: () => context.push('/trade'),
              onActivity: () => context.push('/portfolio/activity'),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          sliver: SliverToBoxAdapter(
            child: _RecentActivitySliver(
              onViewAll: () => context.push('/portfolio/activity'),
            ),
          ),
        ),
        if (snapshot.totalValueUsd > Decimal.zero) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            sliver: SliverToBoxAdapter(
              child: _SectionTitle(l10n.portfolioAllocation),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            sliver: SliverToBoxAdapter(
              child: GlassCard(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                child: AllocationDonut(snapshot: snapshot),
              ),
            ),
          ),
        ],
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          sliver: SliverToBoxAdapter(
            child: _SectionTitle(l10n.portfolioHoldings),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          sliver: SliverList.builder(
            itemCount: snapshot.holdings.length,
            itemBuilder: (context, i) {
              // Slight vertical gap between glass cards.
              return Padding(
                padding: EdgeInsets.only(
                  bottom: i == snapshot.holdings.length - 1 ? 0 : 10,
                ),
                child: GlassCard(
                  padding: EdgeInsets.zero,
                  child: HoldingRow(
                    holding: snapshot.holdings[i],
                    portfolioTotalUsd: snapshot.totalValueUsd,
                  ),
                ),
              );
            },
          ),
        ),
        // Two "coming soon" placeholders so the DeFi / NFT tabs read as
        // intentional gaps rather than missing features.
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ComingSoonCard(
                  icon: Icons.account_balance_wallet_outlined,
                  title: l10n.portfolioPositionsComingSoon,
                ),
                const SizedBox(height: 10),
                _ComingSoonCard(
                  icon: Icons.image_outlined,
                  title: l10n.portfolioNftsComingSoon,
                ),
              ],
            ),
          ),
        ),
      ],
    );

    if (_embedded) return body;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.portfolio)),
      body: SafeArea(child: body),
    );
  }

  /// 24h % change of the whole portfolio, weighted by USD value of each
  /// holding whose symbol has a matching market asset. Returns null if we
  /// can't compute one (no matches, or nothing to weight against).
  static Decimal? _weightedChange24h(
    PortfolioSnapshot snapshot,
    List<MarketAsset> assets,
  ) {
    final bySymbol = {
      for (final a in assets) a.baseSymbol.toUpperCase(): a,
    };
    final total = snapshot.totalValueUsd;
    if (total <= Decimal.zero) return null;
    var acc = Decimal.zero;
    var matched = Decimal.zero;
    for (final h in snapshot.holdings) {
      final asset = bySymbol[h.symbol.toUpperCase()];
      if (asset == null) continue;
      acc += h.valueUsd * asset.change24hPercent;
      matched += h.valueUsd;
    }
    if (matched <= Decimal.zero) return null;
    return (acc / matched).toDecimal(scaleOnInfinitePrecision: 4);
  }

  /// Build a synthetic portfolio trend line by summing per-holding
  /// sparklines (weighted by current holding amount). Length is the min of
  /// the individual series so the summed series is well-formed. If no
  /// symbol has sparkline data, returns an empty list — the hero card will
  /// just omit the line.
  static List<double> _synthesizeTrend(
    PortfolioSnapshot snapshot,
    List<MarketAsset> assets,
    Map<String, List<double>> sparklines,
  ) {
    final assetsBySymbol = {
      for (final a in assets) a.baseSymbol.toUpperCase(): a,
    };
    final available = <String, List<double>>{};
    for (final h in snapshot.holdings) {
      final asset = assetsBySymbol[h.symbol.toUpperCase()];
      if (asset == null) continue;
      final series = sparklines[asset.id];
      if (series == null || series.length < 2) continue;
      available[h.symbol.toUpperCase()] = series;
    }
    if (available.isEmpty) return const [];

    final len = available.values
        .map((s) => s.length)
        .reduce((a, b) => a < b ? a : b);
    final result = List<double>.filled(len, 0);
    for (final h in snapshot.holdings) {
      final series = available[h.symbol.toUpperCase()];
      if (series == null) continue;
      final amount = h.amount.toDouble();
      for (var i = 0; i < len; i++) {
        result[i] += series[i] * amount;
      }
    }
    return result;
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _ComingSoonCard extends StatelessWidget {
  const _ComingSoonCard({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}

/// FutureBuilder-backed activity card. Uses the pending-transaction store
/// directly rather than going through a provider so we don't need a new
/// riverpod family for this small slice of UI.
class _RecentActivitySliver extends ConsumerWidget {
  const _RecentActivitySliver({required this.onViewAll});
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(pendingTransactionStoreProvider);
    return FutureBuilder<List<PendingTransaction>>(
      future: store.loadAll(),
      builder: (context, snap) {
        final items = snap.data ?? const <PendingTransaction>[];
        final sorted = [...items]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return RecentActivityCard(items: sorted, onViewAll: onViewAll);
      },
    );
  }
}

/// Route wrapper — kept in this file so `router.dart` still imports one
/// place for the portfolio screen. Uses a text field so the demo can point
/// the wallet address at any Base account.
class PortfolioRouteScreen extends ConsumerStatefulWidget {
  const PortfolioRouteScreen({required this.address, super.key});
  final String address;

  @override
  ConsumerState<PortfolioRouteScreen> createState() =>
      _PortfolioRouteScreenState();
}

class _PortfolioRouteScreenState extends ConsumerState<PortfolioRouteScreen> {
  late String _address = widget.address;
  late final TextEditingController _addressController =
      TextEditingController(text: widget.address);

  static final _addressPattern = RegExp(r'^0x[a-fA-F0-9]{40}$');

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _applyAddress() {
    final next = _addressController.text.trim();
    if (!_addressPattern.hasMatch(next) || next == _address) return;
    setState(() => _address = next);
  }

  @override
  Widget build(BuildContext context) {
    return ref.watch(portfolioSnapshotProvider(_address)).when(
          data: (snapshot) => Scaffold(
            appBar: AppBar(title: Text(context.l10n.portfolio)),
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _AddressPicker(
                    controller: _addressController,
                    onSubmit: _applyAddress,
                    active: _address,
                  ),
                  Expanded(
                    child: PortfolioScreen.embedded(snapshot: snapshot),
                  ),
                ],
              ),
            ),
          ),
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => Scaffold(
            appBar: AppBar(title: Text(context.l10n.portfolio)),
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _AddressPicker(
                    controller: _addressController,
                    onSubmit: _applyAddress,
                    active: _address,
                  ),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          error.toString(),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
  }
}

class _AddressPicker extends StatelessWidget {
  const _AddressPicker({
    required this.controller,
    required this.onSubmit,
    required this.active,
  });
  final TextEditingController controller;
  final VoidCallback onSubmit;
  final String active;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onSubmitted: (_) => onSubmit(),
              decoration: InputDecoration(
                labelText: l10n.exploreAddress,
                hintText: '0x…',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 96,
            child: FilledButton.tonal(
              onPressed: onSubmit,
              child: Text(l10n.load),
            ),
          ),
        ],
      ),
    );
  }
}
