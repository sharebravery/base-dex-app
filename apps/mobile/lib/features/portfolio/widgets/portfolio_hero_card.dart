import 'package:decimal/decimal.dart';
import 'package:dex_app/core/widgets/glass_card.dart';
import 'package:dex_app/features/portfolio/portfolio_models.dart';
import 'package:dex_app/l10n/l10n_extension.dart';
import 'package:dex_app/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Big-number balance card with a 24h delta pill and a light P&L trend line.
///
/// The trend line is a **synthetic** projection built by weighting each
/// holding's own recent close-price series (from the market screen's
/// sparklines) by its USD value. When no series are available we just fall
/// through — the pill still displays the aggregate 24h delta computed off
/// the market screen's per-asset ticker.
class PortfolioHeroCard extends StatelessWidget {
  const PortfolioHeroCard({
    required this.snapshot,
    this.trend = const [],
    this.change24hPercent,
    super.key,
  });

  final PortfolioSnapshot snapshot;

  /// Close-price series representing the whole portfolio (weighted). Points
  /// don't need to be normalized; the widget scales them itself.
  final List<double> trend;

  /// Aggregate 24h % move across the portfolio (weighted). Optional — if
  /// null the pill is omitted rather than showing "+0.00%".
  final Decimal? change24hPercent;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final positive =
        (change24hPercent ?? Decimal.zero) >= Decimal.zero;
    final pillColor =
        positive ? AppColors.positive : AppColors.negative;

    return GlassCard(
      elevated: true,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.portfolioTotalValue.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 1.2,
                ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '\$${_format(snapshot.totalValueUsd)}',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                ),
              ),
              if (change24hPercent != null) ...[
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: pillColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${positive ? '+' : ''}${_pct(change24hPercent!)}%',
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(
                            color: pillColor,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (trend.length >= 2) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: CustomPaint(
                painter: _TrendPainter(
                  points: trend,
                  color: pillColor,
                ),
                size: const Size.fromHeight(48),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _format(Decimal value) {
    // Big-number formatter tuned for a hero display. Keep dollars &
    // cents up to 6 figures, then abbreviate.
    final d = value.toDouble();
    if (d >= 1e12) return '${(d / 1e12).toStringAsFixed(2)}T';
    if (d >= 1e9) return '${(d / 1e9).toStringAsFixed(2)}B';
    if (d >= 1e6) return '${(d / 1e6).toStringAsFixed(2)}M';
    if (d >= 1000) return d.toStringAsFixed(2);
    if (d >= 1) return d.toStringAsFixed(2);
    if (d >= 0.01) return d.toStringAsFixed(4);
    return d.toStringAsExponential(2);
  }

  static String _pct(Decimal value) {
    final s = value.toString();
    final dot = s.indexOf('.');
    if (dot >= 0 && s.length - dot - 1 > 2) return s.substring(0, dot + 3);
    return s;
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({required this.points, required this.color});
  final List<double> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    var minY = points.first;
    var maxY = points.first;
    for (final p in points) {
      if (p < minY) minY = p;
      if (p > maxY) maxY = p;
    }
    if (minY == maxY) {
      minY -= 1;
      maxY += 1;
    }

    final path = Path();
    final fill = Path();
    for (var i = 0; i < points.length; i++) {
      final x = size.width * (i / (points.length - 1));
      final t = (points[i] - minY) / (maxY - minY);
      final y = size.height - t * size.height;
      if (i == 0) {
        path.moveTo(x, y);
        fill.moveTo(x, size.height);
        fill.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fill.lineTo(x, y);
      }
    }
    fill.lineTo(size.width, size.height);
    fill.close();
    canvas.drawPath(
      fill,
      Paint()..color = color.withValues(alpha: 0.18),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) =>
      !identical(old.points, points) || old.color != color;
}
