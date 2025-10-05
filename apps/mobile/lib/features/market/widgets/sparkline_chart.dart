import 'package:dex_app/theme/app_colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Small close-price line, colored by 7d direction (up vs down). Renders
/// nothing when there aren't enough points to draw a meaningful line — the
/// caller should reserve space (e.g. a fixed-width SizedBox) so the tile row
/// doesn't shift when sparkline data lands.
class SparklineChart extends StatelessWidget {
  const SparklineChart({required this.points, super.key});

  final List<double> points;

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) return const SizedBox.expand();

    final color = points.last >= points.first
        ? AppColors.positive
        : AppColors.negative;

    // Compute the y-window manually so a flat series still renders as a
    // horizontal line rather than collapsing to a single pixel.
    var minY = points.first;
    var maxY = points.first;
    for (final p in points) {
      if (p < minY) minY = p;
      if (p > maxY) maxY = p;
    }
    if (minY == maxY) {
      final pad = minY.abs() * 0.01 + 1;
      minY -= pad;
      maxY += pad;
    } else {
      final pad = (maxY - minY) * 0.1;
      minY -= pad;
      maxY += pad;
    }

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        titlesData: const FlTitlesData(show: false),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i]),
            ],
            isCurved: true,
            barWidth: 1.6,
            color: color,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}
