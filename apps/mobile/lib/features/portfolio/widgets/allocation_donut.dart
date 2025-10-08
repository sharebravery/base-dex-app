import 'dart:math' as math;

import 'package:decimal/decimal.dart';
import 'package:dex_app/features/portfolio/portfolio_models.dart';
import 'package:dex_app/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Donut chart of the portfolio's USD allocation, plus a symbol/percent
/// legend to its right. Tapping a slice highlights it and swaps the
/// centre label to that holding's USD value; tap again (or the legend
/// row) to clear.
class AllocationDonut extends StatefulWidget {
  const AllocationDonut({required this.snapshot, super.key});

  final PortfolioSnapshot snapshot;

  @override
  State<AllocationDonut> createState() => _AllocationDonutState();
}

class _AllocationDonutState extends State<AllocationDonut> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final total = widget.snapshot.totalValueUsd.toDouble();
    if (total <= 0) return const SizedBox.shrink();

    final slices = <_Slice>[];
    for (var i = 0; i < widget.snapshot.holdings.length; i++) {
      final h = widget.snapshot.holdings[i];
      final v = h.valueUsd.toDouble();
      if (v <= 0) continue;
      slices.add(
        _Slice(
          symbol: h.symbol,
          value: v,
          valueDecimal: h.valueUsd,
          fraction: v / total,
          color: _colorFor(h.symbol, i),
        ),
      );
    }
    if (slices.isEmpty) return const SizedBox.shrink();

    // Clamp selection to the slice range (list may have shrunk).
    final selectedIndex = (_selectedIndex != null && _selectedIndex! < slices.length)
        ? _selectedIndex
        : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 132,
          height: 132,
          child: GestureDetector(
            onTapUp: (details) => _handleTap(details, slices),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(132, 132),
                  painter: _DonutPainter(
                    slices: slices,
                    selectedIndex: selectedIndex,
                  ),
                ),
                _CenterLabel(
                  slices: slices,
                  selectedIndex: selectedIndex,
                  total: widget.snapshot.totalValueUsd,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < slices.length; i++)
                _LegendRow(
                  slice: slices[i],
                  selected: i == selectedIndex,
                  onTap: () => setState(() {
                    _selectedIndex = i == selectedIndex ? null : i;
                  }),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleTap(TapUpDetails details, List<_Slice> slices) {
    // Compute the angle of the tapped position relative to the donut
    // centre, mapped to the same 12-o'clock-clockwise convention the
    // painter uses, and find which slice contains it. Reject taps that
    // fall outside the ring so slice-vs-hole clicks feel intentional.
    const size = 132.0;
    const centre = Offset(size / 2, size / 2);
    final offset = details.localPosition - centre;
    final distance = offset.distance;
    final radius = size / 2;
    final ringWidth = radius * 0.28;
    final innerRadius = radius - ringWidth;
    if (distance < innerRadius || distance > radius) {
      // Tap on the hole or outside the disc — clear selection.
      setState(() => _selectedIndex = null);
      return;
    }
    var angle = math.atan2(offset.dy, offset.dx) - (-math.pi / 2);
    if (angle < 0) angle += math.pi * 2;
    var acc = 0.0;
    for (var i = 0; i < slices.length; i++) {
      final sweep = slices[i].fraction * math.pi * 2;
      if (angle >= acc && angle < acc + sweep) {
        setState(() {
          _selectedIndex = i == _selectedIndex ? null : i;
        });
        return;
      }
      acc += sweep;
    }
  }

  static Color _colorFor(String symbol, int index) {
    switch (symbol.toUpperCase()) {
      case 'ETH':
        return const Color(0xFF627EEA);
      case 'USDC':
        return const Color(0xFF2775CA);
      case 'BTC':
        return const Color(0xFFF7931A);
      case 'SOL':
        return const Color(0xFF14F195);
    }
    const palette = [
      AppColors.gradientStart,
      AppColors.gradientEnd,
      AppColors.positive,
      AppColors.warning,
      AppColors.negative,
    ];
    return palette[index % palette.length];
  }
}

class _Slice {
  const _Slice({
    required this.symbol,
    required this.value,
    required this.valueDecimal,
    required this.fraction,
    required this.color,
  });
  final String symbol;
  final double value;
  final Decimal valueDecimal;
  final double fraction;
  final Color color;
}

class _CenterLabel extends StatelessWidget {
  const _CenterLabel({
    required this.slices,
    required this.selectedIndex,
    required this.total,
  });
  final List<_Slice> slices;
  final int? selectedIndex;
  final Decimal total;

  @override
  Widget build(BuildContext context) {
    final slice = selectedIndex == null ? null : slices[selectedIndex!];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          slice == null ? 'Total' : slice.symbol,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textMuted,
                letterSpacing: 1.1,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          '\$${_formatUsd(slice == null ? total : slice.valueDecimal)}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: slice?.color ?? AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
        ),
        if (slice != null) ...[
          const SizedBox(height: 2),
          Text(
            '${(slice.fraction * 100).toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ],
    );
  }

  static String _formatUsd(Decimal value) {
    final d = value.toDouble();
    if (d >= 1e9) return '${(d / 1e9).toStringAsFixed(2)}B';
    if (d >= 1e6) return '${(d / 1e6).toStringAsFixed(2)}M';
    if (d >= 1000) return d.toStringAsFixed(0);
    if (d >= 1) return d.toStringAsFixed(2);
    return d.toStringAsFixed(2);
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.slice,
    required this.selected,
    required this.onTap,
  });
  final _Slice slice;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final percent = (slice.fraction * 100).toStringAsFixed(1);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? slice.color.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: slice.color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              slice.symbol,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: selected ? slice.color : null,
                  ),
            ),
            const Spacer(),
            Text(
              '$percent%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.slices, required this.selectedIndex});
  final List<_Slice> slices;
  final int? selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final ringWidth = radius * 0.28;

    final trackPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringWidth;
    canvas.drawCircle(center, radius - ringWidth / 2, trackPaint);

    var start = -math.pi / 2;
    for (var i = 0; i < slices.length; i++) {
      final s = slices[i];
      final sweep = s.fraction * math.pi * 2;
      final selected = i == selectedIndex;
      final paint = Paint()
        ..color = selected
            ? s.color
            : s.color.withValues(alpha: selectedIndex == null ? 1.0 : 0.42)
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? ringWidth + 4 : ringWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - ringWidth / 2),
        start,
        sweep,
        false,
        paint,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      !identical(old.slices, slices) ||
      old.selectedIndex != selectedIndex;
}
