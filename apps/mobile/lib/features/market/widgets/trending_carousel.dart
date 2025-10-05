import 'package:decimal/decimal.dart';
import 'package:dex_app/core/widgets/glass_card.dart';
import 'package:dex_app/features/market/market_models.dart';
import 'package:dex_app/features/market/widgets/sparkline_chart.dart';
import 'package:dex_app/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Horizontal scroller of "highlighted" assets. Two flavors:
///
/// - `TrendingCarousel.gainers(...)` — top 5 by 24h %
/// - `TrendingCarousel.losers(...)`  — bottom 5 by 24h %
///
/// USDC-style flat placeholders (0% change, 0 volume) are filtered out so the
/// list is never dominated by stables.
class TrendingCarousel extends StatelessWidget {
  const TrendingCarousel._({
    required this.title,
    required this.assets,
    required this.onTap,
    required this.emphasisPositive,
  });

  /// Top gainers strip.
  factory TrendingCarousel.gainers({
    Key? key,
    required List<MarketAsset> assets,
    required String title,
    required ValueChanged<MarketAsset> onTap,
  }) {
    final ranked = _rank(assets, descending: true);
    return TrendingCarousel._(
      title: title,
      assets: ranked,
      onTap: onTap,
      emphasisPositive: true,
    );
  }

  /// Top losers strip.
  factory TrendingCarousel.losers({
    Key? key,
    required List<MarketAsset> assets,
    required String title,
    required ValueChanged<MarketAsset> onTap,
  }) {
    final ranked = _rank(assets, descending: false);
    return TrendingCarousel._(
      title: title,
      assets: ranked,
      onTap: onTap,
      emphasisPositive: false,
    );
  }

  final String title;
  final List<MarketAsset> assets;
  final ValueChanged<MarketAsset> onTap;
  final bool emphasisPositive;

  static List<MarketAsset> _rank(
    List<MarketAsset> assets, {
    required bool descending,
  }) {
    final tradable = [
      for (final a in assets)
        if (a.volume24hUsd > Decimal.zero) a,
    ]..sort(
        (a, b) => descending
            ? b.change24hPercent.compareTo(a.change24hPercent)
            : a.change24hPercent.compareTo(b.change24hPercent),
      );
    return tradable.take(5).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    if (assets.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              Icon(
                emphasisPositive ? Icons.trending_up : Icons.trending_down,
                size: 16,
                color: emphasisPositive
                    ? AppColors.positive
                    : AppColors.negative,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 128,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: assets.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final asset = assets[index];
              return _TrendingCard(asset: asset, onTap: () => onTap(asset));
            },
          ),
        ),
      ],
    );
  }
}

class _TrendingCard extends StatelessWidget {
  const _TrendingCard({required this.asset, required this.onTap});

  final MarketAsset asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final positive = asset.change24hPercent >= Decimal.zero;
    final changeColor = positive ? AppColors.positive : AppColors.negative;
    return SizedBox(
      width: 168,
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  asset.baseSymbol,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: changeColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${positive ? '+' : ''}${_pct(asset.change24hPercent)}%',
                    style:
                        Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: changeColor,
                              fontWeight: FontWeight.w600,
                            ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '\$${_price(asset.priceUsd)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const Spacer(),
            SizedBox(
              height: 40,
              child: SparklineChart(points: asset.sparkline),
            ),
          ],
        ),
      ),
    );
  }

  static String _pct(Decimal value) {
    final s = value.toString();
    final dot = s.indexOf('.');
    if (dot >= 0 && s.length - dot - 1 > 2) return s.substring(0, dot + 3);
    return s;
  }

  static String _price(Decimal value) {
    final d = value.toDouble();
    if (d >= 1000) return d.toStringAsFixed(2);
    if (d >= 1) return d.toStringAsFixed(3);
    if (d >= 0.01) return d.toStringAsFixed(4);
    if (d >= 0.0001) return d.toStringAsFixed(6);
    return d.toStringAsExponential(2);
  }
}
