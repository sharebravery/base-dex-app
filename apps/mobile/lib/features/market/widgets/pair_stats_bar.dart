import 'package:decimal/decimal.dart';
import 'package:dex_app/features/market/market_models.dart';
import 'package:dex_app/l10n/l10n_extension.dart';
import 'package:dex_app/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Horizontal strip of 24h statistics for the pair-detail hero. Renders a
/// row on wide layouts and a 2×2 grid on narrow ones so the numbers never
/// squish beyond legibility.
class PairStatsBar extends StatelessWidget {
  const PairStatsBar({required this.asset, super.key});

  final MarketAsset asset;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stats = <_Stat>[
      _Stat(
        label: l10n.stat24hHigh,
        value: asset.high24hUsd == null
            ? '—'
            : '\$${_price(asset.high24hUsd!)}',
        accent: AppColors.positive,
      ),
      _Stat(
        label: l10n.stat24hLow,
        value: asset.low24hUsd == null
            ? '—'
            : '\$${_price(asset.low24hUsd!)}',
        accent: AppColors.negative,
      ),
      _Stat(
        label: l10n.stat24hVolume,
        value: asset.volume24hUsd > Decimal.zero
            ? _bigUsd(asset.volume24hUsd)
            : '—',
      ),
      _Stat(
        label: l10n.stat24hChange,
        value: '${asset.change24hPercent >= Decimal.zero ? '+' : ''}${_pct(asset.change24hPercent)}%',
        accent: asset.change24hPercent >= Decimal.zero
            ? AppColors.positive
            : AppColors.negative,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // On narrow screens each cell needs ~90px to render two lines of
        // legible text; if we can't fit all four, drop to a 2-col grid.
        final wide = constraints.maxWidth >= 4 * 90;
        if (wide) {
          return Row(
            children: [
              for (var i = 0; i < stats.length; i++) ...[
                Expanded(child: _StatCell(stat: stats[i])),
                if (i != stats.length - 1)
                  Container(
                    width: 1,
                    height: 34,
                    color: AppColors.border,
                  ),
              ],
            ],
          );
        }
        return Column(
          children: [
            Row(
              children: [
                Expanded(child: _StatCell(stat: stats[0])),
                Container(width: 1, height: 34, color: AppColors.border),
                Expanded(child: _StatCell(stat: stats[1])),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _StatCell(stat: stats[2])),
                Container(width: 1, height: 34, color: AppColors.border),
                Expanded(child: _StatCell(stat: stats[3])),
              ],
            ),
          ],
        );
      },
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

  static String _bigUsd(Decimal value) {
    final d = value.toDouble();
    if (d >= 1e12) return '\$${(d / 1e12).toStringAsFixed(2)}T';
    if (d >= 1e9) return '\$${(d / 1e9).toStringAsFixed(2)}B';
    if (d >= 1e6) return '\$${(d / 1e6).toStringAsFixed(1)}M';
    if (d >= 1e3) return '\$${(d / 1e3).toStringAsFixed(1)}K';
    return '\$${d.toStringAsFixed(0)}';
  }
}

class _Stat {
  const _Stat({required this.label, required this.value, this.accent});
  final String label;
  final String value;
  final Color? accent;
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.stat});
  final _Stat stat;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            stat.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            stat.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: stat.accent ?? AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
