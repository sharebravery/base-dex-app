import 'package:decimal/decimal.dart';
import 'package:dex_app/core/widgets/glass_card.dart';
import 'package:dex_app/features/market/market_models.dart';
import 'package:dex_app/l10n/l10n_extension.dart';
import 'package:dex_app/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Top-of-market summary card. Everything derives from the same asset list
/// the tiles below use, so this card and the list are always self-consistent
/// even if Binance ticker data is stale.
class MarketHeroCard extends StatelessWidget {
  const MarketHeroCard({required this.assets, super.key});

  final List<MarketAsset> assets;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final totalVolume = assets.fold<Decimal>(
      Decimal.zero,
      (acc, a) => acc + a.volume24hUsd,
    );

    // Consider only ticker-backed assets for gainer/loser — the USDC stable
    // placeholder is always 0% and would win "least volatile" by default.
    final ranked = [
      for (final a in assets)
        if (a.volume24hUsd > Decimal.zero) a,
    ]..sort((a, b) => b.change24hPercent.compareTo(a.change24hPercent));
    final topGainer = ranked.isNotEmpty ? ranked.first : null;
    final topLoser = ranked.isNotEmpty ? ranked.last : null;

    // Rough market breadth: fraction of tracked assets in the green.
    final tracked = ranked.length;
    final greens = ranked
        .where((a) => a.change24hPercent >= Decimal.zero)
        .length;
    final breadth = tracked == 0 ? 0.0 : greens / tracked;

    return GlassCard(
      elevated: true,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.marketOverview,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 1.2,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _formatBigUsd(totalVolume),
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  l10n.marketVolume24h,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 3 stats laid out in a Row. On very narrow devices they'd overflow;
          // let the last one Wrap by keeping them in `IntrinsicHeight` so the
          // divider height matches the tallest child.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _Stat(
                    label: l10n.marketAssets,
                    value: '${assets.length}',
                  ),
                ),
                const VerticalDivider(color: AppColors.border, width: 1),
                Expanded(
                  child: _Stat(
                    label: l10n.marketBreadth,
                    value: '${(breadth * 100).toStringAsFixed(0)}%',
                    accent: breadth >= 0.5
                        ? AppColors.positive
                        : AppColors.negative,
                  ),
                ),
                const VerticalDivider(color: AppColors.border, width: 1),
                Expanded(
                  child: _Stat(
                    label: l10n.marketMovers,
                    value: topGainer == null
                        ? '—'
                        : topGainer.baseSymbol,
                    accent: AppColors.positive,
                    sub: topGainer == null
                        ? null
                        : '+${_pct(topGainer.change24hPercent)}%',
                  ),
                ),
              ],
            ),
          ),
          if (topLoser != null && topLoser.id != topGainer?.id) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.trending_down,
                  size: 14,
                  color: AppColors.negative,
                ),
                const SizedBox(width: 6),
                Text(
                  '${l10n.marketWorst}: ${topLoser.baseSymbol} ${_pct(topLoser.change24hPercent)}%',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _pct(Decimal v) {
    final s = v.toString();
    final dot = s.indexOf('.');
    if (dot >= 0 && s.length - dot - 1 > 2) return s.substring(0, dot + 3);
    return s;
  }

  /// Big USD summary formatter: $3.4T / $812.4B / $412.1M.
  static String _formatBigUsd(Decimal value) {
    final d = value.toDouble();
    if (d >= 1e12) return '\$${(d / 1e12).toStringAsFixed(2)}T';
    if (d >= 1e9) return '\$${(d / 1e9).toStringAsFixed(2)}B';
    if (d >= 1e6) return '\$${(d / 1e6).toStringAsFixed(1)}M';
    return '\$${d.toStringAsFixed(0)}';
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    this.sub,
    this.accent,
  });

  final String label;
  final String value;
  final String? sub;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: accent ?? AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (sub != null) ...[
            const SizedBox(height: 2),
            Text(
              sub!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: accent ?? AppColors.textSecondary,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
