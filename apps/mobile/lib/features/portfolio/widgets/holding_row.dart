import 'package:decimal/decimal.dart';
import 'package:dex_app/features/portfolio/portfolio_models.dart';
import 'package:dex_app/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Single-holding tile with a symbol avatar, amount, USD value, and a thin
/// bar showing this holding's share of the portfolio. The row is meant to
/// be embedded in a GlassCard container by the caller.
class HoldingRow extends StatelessWidget {
  const HoldingRow({
    required this.holding,
    required this.portfolioTotalUsd,
    super.key,
  });

  final Holding holding;
  final Decimal portfolioTotalUsd;

  @override
  Widget build(BuildContext context) {
    final total = portfolioTotalUsd.toDouble();
    final value = holding.valueUsd.toDouble();
    final share = total > 0 ? value / total : 0.0;
    final palette = _paletteFor(holding.symbol);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: palette,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  holding.symbol.characters.first,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      holding.symbol,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatAmount(holding.amount),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '\$${_formatUsd(holding.valueUsd)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${(share * 100).toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Thin allocation bar. Fixed-width track + filled fraction — reads
          // as "this slice of the portfolio" without needing a legend.
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Stack(
              children: [
                Container(
                  height: 4,
                  color: AppColors.border.withValues(alpha: 0.6),
                ),
                FractionallySizedBox(
                  widthFactor: share.clamp(0.0, 1.0),
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: palette),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatUsd(Decimal value) {
    final d = value.toDouble();
    if (d >= 1000) return d.toStringAsFixed(2);
    if (d >= 1) return d.toStringAsFixed(2);
    if (d >= 0.01) return d.toStringAsFixed(4);
    return d.toStringAsExponential(2);
  }

  static String _formatAmount(Decimal value) {
    final s = value.toString();
    // Trim to 4 decimal places for on-screen legibility while keeping
    // sub-cent balances (SHIB, PEPE) readable.
    final dot = s.indexOf('.');
    if (dot >= 0 && s.length - dot - 1 > 4) return s.substring(0, dot + 5);
    return s;
  }

  static List<Color> _paletteFor(String symbol) {
    switch (symbol.toUpperCase()) {
      case 'ETH':
        return const [Color(0xFF627EEA), Color(0xFF00E5FF)];
      case 'USDC':
        return const [Color(0xFF2775CA), Color(0xFF00E5FF)];
      case 'BTC':
        return const [Color(0xFFF7931A), Color(0xFFFBBF24)];
      case 'SOL':
        return const [Color(0xFF14F195), Color(0xFF9945FF)];
    }
    return const [AppColors.gradientStart, AppColors.gradientEnd];
  }
}
