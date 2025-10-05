import 'package:decimal/decimal.dart';
import 'package:dex_app/features/market/market_models.dart';
import 'package:dex_app/l10n/l10n_extension.dart';
import 'package:dex_app/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Candlestick chart backed by a CustomPainter with a crosshair overlay
/// and a compact OHLC tooltip that follows the pointer.
///
/// Sparse series (30 daily bars) render as classic red/green candles with
/// wicks. Dense series (720 hourly bars for 30d) fall back to hairline
/// bars — thin vertical lines from low → high with a slightly thicker
/// open-to-close segment — so bars don't overlap.
class CandlestickChart extends StatefulWidget {
  const CandlestickChart({required this.candles, super.key});

  final List<Candle> candles;

  @override
  State<CandlestickChart> createState() => _CandlestickChartState();
}

class _CandlestickChartState extends State<CandlestickChart> {
  /// Index of the candle currently highlighted by the crosshair, or null
  /// when the pointer is off the chart.
  int? _hoverIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.candles.length < 2) {
      return const SizedBox.expand();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return MouseRegion(
          cursor: SystemMouseCursors.precise,
          onExit: (_) => setState(() => _hoverIndex = null),
          child: Listener(
            onPointerHover: (event) =>
                _updateHover(event.localPosition, size),
            onPointerDown: (event) =>
                _updateHover(event.localPosition, size),
            onPointerMove: (event) =>
                _updateHover(event.localPosition, size),
            onPointerUp: (_) => setState(() => _hoverIndex = null),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CandlestickPainter(
                      candles: widget.candles,
                      gridColor: AppColors.border,
                      axisTextStyle:
                          Theme.of(context).textTheme.labelSmall!.copyWith(
                                color: AppColors.textSecondary,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                      hoverIndex: _hoverIndex,
                    ),
                  ),
                ),
                if (_hoverIndex != null)
                  _TooltipOverlay(
                    candles: widget.candles,
                    hoverIndex: _hoverIndex!,
                    size: size,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _updateHover(Offset local, Size size) {
    final chartWidth = size.width - _CandlestickPainter._rightAxisWidth;
    if (local.dx < 0 || local.dx > chartWidth || local.dy < 0 ||
        local.dy > size.height) {
      if (_hoverIndex != null) setState(() => _hoverIndex = null);
      return;
    }
    final slot = chartWidth / widget.candles.length;
    final idx = (local.dx / slot).floor().clamp(0, widget.candles.length - 1);
    if (idx != _hoverIndex) setState(() => _hoverIndex = idx);
  }
}

class _CandlestickPainter extends CustomPainter {
  _CandlestickPainter({
    required this.candles,
    required this.gridColor,
    required this.axisTextStyle,
    required this.hoverIndex,
  });

  final List<Candle> candles;
  final Color gridColor;
  final TextStyle axisTextStyle;
  final int? hoverIndex;

  static const double _rightAxisWidth = 48;

  @override
  void paint(Canvas canvas, Size size) {
    final chartWidth = size.width - _rightAxisWidth;
    final chartRect = Rect.fromLTWH(0, 0, chartWidth, size.height);

    double minY = candles.first.low.toDouble();
    double maxY = candles.first.high.toDouble();
    for (final c in candles) {
      final l = c.low.toDouble();
      final h = c.high.toDouble();
      if (l < minY) minY = l;
      if (h > maxY) maxY = h;
    }
    final pad = (maxY - minY) * 0.06;
    minY -= pad;
    maxY += pad;

    _drawGrid(canvas, chartRect);

    final barSlot = chartRect.width / candles.length;
    final dense = candles.length > 120;

    for (var i = 0; i < candles.length; i++) {
      final c = candles[i];
      final open = c.open.toDouble();
      final close = c.close.toDouble();
      final high = c.high.toDouble();
      final low = c.low.toDouble();
      final rising = close >= open;
      final color = rising ? AppColors.positive : AppColors.negative;

      final xCenter = chartRect.left + barSlot * (i + 0.5);
      final yOpen = _yFor(open, chartRect, minY, maxY);
      final yClose = _yFor(close, chartRect, minY, maxY);
      final yHigh = _yFor(high, chartRect, minY, maxY);
      final yLow = _yFor(low, chartRect, minY, maxY);

      if (dense) {
        final linePaint = Paint()
          ..color = color
          ..strokeWidth = 1
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
            Offset(xCenter, yHigh), Offset(xCenter, yLow), linePaint);
        canvas.drawLine(
          Offset(xCenter, yOpen),
          Offset(xCenter, yClose),
          Paint()
            ..color = color
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round,
        );
      } else {
        final wickPaint = Paint()
          ..color = color
          ..strokeWidth = 1;
        canvas.drawLine(
            Offset(xCenter, yHigh), Offset(xCenter, yLow), wickPaint);

        final bodyWidth = (barSlot * 0.62).clamp(2.0, 12.0);
        final bodyRect = Rect.fromLTRB(
          xCenter - bodyWidth / 2,
          rising ? yClose : yOpen,
          xCenter + bodyWidth / 2,
          rising ? yOpen : yClose,
        );
        final bodyPaint = Paint()..color = color;
        if (bodyRect.height < 1) {
          canvas.drawLine(
            Offset(bodyRect.left, bodyRect.top),
            Offset(bodyRect.right, bodyRect.top),
            bodyPaint..strokeWidth = 1,
          );
        } else {
          canvas.drawRect(bodyRect, bodyPaint);
        }
      }
    }

    _drawAxis(canvas, size, minY, maxY);
    if (hoverIndex != null) {
      _drawCrosshair(canvas, chartRect, barSlot, minY, maxY);
    }
  }

  double _yFor(double value, Rect rect, double minY, double maxY) {
    final t = (value - minY) / (maxY - minY);
    return rect.bottom - t * rect.height;
  }

  void _drawGrid(Canvas canvas, Rect chartRect) {
    final paint = Paint()
      ..color = gridColor.withValues(alpha: 0.4)
      ..strokeWidth = 0.5;
    for (var i = 1; i <= 3; i++) {
      final y = chartRect.top + chartRect.height * (i / 4);
      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        paint,
      );
    }
  }

  void _drawCrosshair(
    Canvas canvas,
    Rect chartRect,
    double barSlot,
    double minY,
    double maxY,
  ) {
    final i = hoverIndex!;
    final candle = candles[i];
    final xCenter = chartRect.left + barSlot * (i + 0.5);
    final closeY = _yFor(candle.close.toDouble(), chartRect, minY, maxY);
    final line = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.6)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    // Dashed vertical line: 6px on, 4px off.
    _drawDashedLine(
      canvas,
      Offset(xCenter, chartRect.top),
      Offset(xCenter, chartRect.bottom),
      line,
    );
    _drawDashedLine(
      canvas,
      Offset(chartRect.left, closeY),
      Offset(chartRect.right, closeY),
      line,
    );

    // Price label bubble on the right axis at close price.
    final tp = TextPainter(
      text: TextSpan(
        text: _formatTick(candle.close.toDouble()),
        style: axisTextStyle.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final bubbleRect = Rect.fromLTWH(
      chartRect.right + 2,
      closeY - tp.height / 2 - 2,
      tp.width + 8,
      tp.height + 4,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bubbleRect, const Radius.circular(3)),
      Paint()..color = AppColors.accent,
    );
    tp.paint(canvas, Offset(bubbleRect.left + 4, bubbleRect.top + 2));
  }

  static void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
  ) {
    const dash = 6.0;
    const gap = 4.0;
    final total = (end - start).distance;
    if (total <= 0) return;
    final dir = (end - start) / total;
    var travelled = 0.0;
    while (travelled < total) {
      final a = start + dir * travelled;
      final b = start + dir * (travelled + dash).clamp(0, total);
      canvas.drawLine(a, b, paint);
      travelled += dash + gap;
    }
  }

  void _drawAxis(Canvas canvas, Size size, double minY, double maxY) {
    for (var i = 0; i <= 3; i++) {
      final frac = i / 3;
      final value = maxY - frac * (maxY - minY);
      final y = size.height * frac;
      final tp = TextPainter(
        text: TextSpan(text: _formatTick(value), style: axisTextStyle),
        textDirection: TextDirection.ltr,
      )..layout(minWidth: 0, maxWidth: _rightAxisWidth);
      final dy = i == 0
          ? y
          : (i == 3 ? y - tp.height : y - tp.height / 2);
      tp.paint(canvas, Offset(size.width - tp.width, dy));
    }
  }

  static String _formatTick(double v) {
    if (v.abs() >= 10_000) return v.toStringAsFixed(0);
    if (v.abs() >= 100) return v.toStringAsFixed(1);
    if (v.abs() >= 1) return v.toStringAsFixed(2);
    if (v.abs() >= 0.01) return v.toStringAsFixed(4);
    if (v.abs() >= 0.0001) return v.toStringAsFixed(6);
    return v.toStringAsExponential(2);
  }

  @override
  bool shouldRepaint(covariant _CandlestickPainter old) {
    return !identical(old.candles, candles) || old.hoverIndex != hoverIndex;
  }
}

/// Small OHLC tooltip that follows the pointer. Positioned in absolute
/// coordinates within the chart so it never gets clipped by the parent
/// scroll view.
class _TooltipOverlay extends StatelessWidget {
  const _TooltipOverlay({
    required this.candles,
    required this.hoverIndex,
    required this.size,
  });

  final List<Candle> candles;
  final int hoverIndex;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final chartWidth = size.width - _CandlestickPainter._rightAxisWidth;
    final slot = chartWidth / candles.length;
    final xCenter = slot * (hoverIndex + 0.5);
    final candle = candles[hoverIndex];

    // Pin the tooltip near the top; nudge to the opposite side if the
    // pointer is on the right so the bubble stays inside the chart.
    const width = 132.0;
    final left = xCenter + 12 + width > chartWidth
        ? (xCenter - width - 12).clamp(0.0, chartWidth - width)
        : xCenter + 12;

    final rising = candle.close >= candle.open;
    final color = rising ? AppColors.positive : AppColors.negative;
    final l10n = context.l10n;

    return Positioned(
      left: left.toDouble(),
      top: 8,
      child: IgnorePointer(
        child: Container(
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x99000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(candle.timestamp),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
              ),
              const SizedBox(height: 4),
              _KV(l10n.candleOpen, _formatPrice(candle.open), color),
              _KV(l10n.candleHigh, _formatPrice(candle.high), color),
              _KV(l10n.candleLow, _formatPrice(candle.low), color),
              _KV(l10n.candleClose, _formatPrice(candle.close), color),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatPrice(Decimal v) {
    final d = v.toDouble();
    if (d >= 10_000) return d.toStringAsFixed(0);
    if (d >= 1000) return d.toStringAsFixed(1);
    if (d >= 1) return d.toStringAsFixed(2);
    if (d >= 0.01) return d.toStringAsFixed(4);
    if (d >= 0.0001) return d.toStringAsFixed(6);
    return d.toStringAsExponential(2);
  }

  static String _formatTime(DateTime t) {
    final local = t.toLocal();
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${pad(local.month)}-${pad(local.day)} '
        '${pad(local.hour)}:${pad(local.minute)}';
  }
}

class _KV extends StatelessWidget {
  const _KV(this.k, this.v, this.color);
  final String k;
  final String v;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          SizedBox(
            width: 14,
            child: Text(
              k,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
          ),
          const Spacer(),
          Text(
            v,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
