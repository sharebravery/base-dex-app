import 'package:decimal/decimal.dart';
import 'package:dex_app/features/market/market_models.dart';
import 'package:dex_app/features/market/market_providers.dart';
import 'package:dex_app/features/market/widgets/candlestick_chart.dart';
import 'package:dex_app/features/market/widgets/pair_stats_bar.dart';
import 'package:dex_app/features/market/widgets/recent_trades_tape.dart';
import 'package:dex_app/l10n/l10n_extension.dart';
import 'package:dex_app/theme/app_colors.dart';
import 'package:fl_chart/fl_chart.dart' hide CandlestickChart;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _intervals = <_IntervalOption>[
  _IntervalOption('1d', '1D'),
  _IntervalOption('7d', '7D'),
  _IntervalOption('30d', '30D'),
];

enum _ChartMode { line, candles }

class PairDetailScreen extends ConsumerStatefulWidget {
  const PairDetailScreen({required this.assetId, super.key});

  final String assetId;

  @override
  ConsumerState<PairDetailScreen> createState() => _PairDetailScreenState();
}

class _PairDetailScreenState extends ConsumerState<PairDetailScreen> {
  String _interval = '1d';
  _ChartMode _mode = _ChartMode.candles;

  @override
  Widget build(BuildContext context) {
    final assetsAsync = ref.watch(marketAssetsProvider);
    return Scaffold(
      appBar: AppBar(
        title: assetsAsync.when(
          data: (assets) {
            final asset = _findAsset(assets, widget.assetId);
            if (asset == null) return Text(widget.assetId);
            return Text(
              asset.tradable
                  ? '${asset.baseSymbol} / ${asset.quoteSymbol}'
                  : asset.baseSymbol,
            );
          },
          loading: () => Text(widget.assetId),
          error: (_, _) => Text(widget.assetId),
        ),
      ),
      body: SafeArea(
        child: assetsAsync.when(
          data: (assets) {
            final asset = _findAsset(assets, widget.assetId);
            if (asset == null) {
              return Center(child: Text(context.l10n.noData));
            }
            return _Body(
              asset: asset,
              interval: _interval,
              mode: _mode,
              onInterval: (v) => setState(() => _interval = v),
              onMode: (m) => setState(() => _mode = m),
              onSwap: asset.tradable ? () => context.push('/trade') : null,
            );
          },
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(e.toString())),
        ),
      ),
    );
  }

  MarketAsset? _findAsset(List<MarketAsset> assets, String id) {
    for (final a in assets) {
      if (a.id == id) return a;
    }
    return null;
  }
}

class _IntervalOption {
  const _IntervalOption(this.key, this.label);
  final String key;
  final String label;
}

class _Body extends StatelessWidget {
  const _Body({
    required this.asset,
    required this.interval,
    required this.mode,
    required this.onInterval,
    required this.onMode,
    required this.onSwap,
  });

  final MarketAsset asset;
  final String interval;
  final _ChartMode mode;
  final ValueChanged<String> onInterval;
  final ValueChanged<_ChartMode> onMode;
  final VoidCallback? onSwap;

  @override
  Widget build(BuildContext context) {
    final positive = asset.change24hPercent >= Decimal.zero;
    final changeColor =
        positive ? AppColors.positive : AppColors.negative;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          sliver: SliverToBoxAdapter(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '\$${_price(asset.priceUsd)}',
                      style:
                          Theme.of(context).textTheme.displaySmall,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: changeColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${positive ? '+' : ''}${_pct(asset.change24hPercent)}%',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(
                            color: changeColor,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: PairStatsBar(asset: asset),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<String>(
                    segments: [
                      for (final o in _intervals)
                        ButtonSegment(
                          value: o.key,
                          label: Text(o.label),
                        ),
                    ],
                    selected: {interval},
                    onSelectionChanged: (s) => onInterval(s.first),
                  ),
                ),
                const SizedBox(width: 8),
                _ChartModeToggle(mode: mode, onChanged: onMode),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 300,
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: _Chart(
                assetId: asset.id,
                interval: interval,
                mode: mode,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: FilledButton(
              onPressed: onSwap,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: Text(
                asset.tradable
                    ? context.l10n.swap
                    : context.l10n.marketDataOnly,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          sliver: SliverToBoxAdapter(
            child: Text(
              context.l10n.recentTrades,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _RecentTradesSection(asset: asset),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          sliver: SliverToBoxAdapter(
            child: Text(
              context.l10n.aboutAsset(asset.name),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ),
        SliverPadding(
          padding:
              const EdgeInsets.fromLTRB(16, 8, 16, 32),
          sliver: SliverToBoxAdapter(
            child: Text(
              _blurbFor(context, asset.id),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
            ),
          ),
        ),
      ],
    );
  }

  static String _blurbFor(BuildContext context, String id) {
    final l10n = context.l10n;
    return switch (id) {
      'bitcoin' => l10n.aboutBitcoin,
      'ethereum' => l10n.aboutEthereum,
      'solana' => l10n.aboutSolana,
      _ => l10n.aboutGeneric,
    };
  }

  static String _price(Decimal value) {
    final d = value.toDouble();
    if (d >= 1000) return d.toStringAsFixed(2);
    if (d >= 1) return d.toStringAsFixed(3);
    if (d >= 0.01) return d.toStringAsFixed(4);
    if (d >= 0.0001) return d.toStringAsFixed(6);
    return d.toStringAsExponential(3);
  }

  static String _pct(Decimal value) {
    final s = value.toString();
    final dot = s.indexOf('.');
    if (dot >= 0 && s.length - dot - 1 > 2) return s.substring(0, dot + 3);
    return s;
  }
}

class _ChartModeToggle extends StatelessWidget {
  const _ChartModeToggle({required this.mode, required this.onChanged});
  final _ChartMode mode;
  final ValueChanged<_ChartMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<_ChartMode>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(
          value: _ChartMode.line,
          icon: Icon(Icons.show_chart, size: 18),
        ),
        ButtonSegment(
          value: _ChartMode.candles,
          icon: Icon(Icons.candlestick_chart, size: 18),
        ),
      ],
      selected: {mode},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

class _Chart extends ConsumerWidget {
  const _Chart({
    required this.assetId,
    required this.interval,
    required this.mode,
  });
  final String assetId;
  final String interval;
  final _ChartMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(
      candlesProvider(CandlesQuery(assetId: assetId, interval: interval)),
    );
    return Card(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
        child: async.when(
          data: (candles) {
            if (candles.isEmpty) {
              return Center(child: Text(context.l10n.noData));
            }
            if (mode == _ChartMode.line) {
              return _PriceLine(candles: candles);
            }
            return CandlestickChart(candles: candles);
          },
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: Text(
              context.l10n.chartUnavailable,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ),
    );
  }
}

class _PriceLine extends StatelessWidget {
  const _PriceLine({required this.candles});
  final List<Candle> candles;

  @override
  Widget build(BuildContext context) {
    // Sample to at most 64 points, but keep the original candle index for
    // each sample so the tooltip can report the actual OHLC timestamp.
    final samples = _sample(candles, 64);
    final points = [
      for (var i = 0; i < samples.length; i++)
        FlSpot(i.toDouble(), samples[i].value),
    ];
    final minY = points.map((p) => p.y).reduce((a, b) => a < b ? a : b);
    final maxY = points.map((p) => p.y).reduce((a, b) => a > b ? a : b);
    final pad = (maxY - minY) * 0.08;
    final theme = Theme.of(context);
    final up = candles.last.close >= candles.first.open;
    final color = up ? AppColors.positive : AppColors.negative;
    return LineChart(
      LineChartData(
        minY: minY - pad,
        maxY: maxY + pad,
        titlesData: const FlTitlesData(show: false),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY) / 3,
          getDrawingHorizontalLine: (_) => FlLine(
            color: theme.dividerColor.withValues(alpha: 0.3),
            strokeWidth: 0.5,
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.surfaceElevated,
            tooltipPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            tooltipBorderRadius: BorderRadius.circular(8),
            tooltipBorder:
                const BorderSide(color: AppColors.border, width: 1),
            getTooltipItems: (spots) => [
              for (final s in spots)
                LineTooltipItem(
                  '',
                  Theme.of(context).textTheme.labelSmall!,
                  children: [
                    TextSpan(
                      text: '\$${_formatPrice(s.y)}\n',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    TextSpan(
                      text: _formatTime(
                        samples[s.spotIndex].timestamp,
                      ),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          getTouchedSpotIndicator: (bar, indices) => [
            for (final _ in indices)
              TouchedSpotIndicatorData(
                FlLine(
                  color: AppColors.accent.withValues(alpha: 0.6),
                  strokeWidth: 1,
                  dashArray: const [4, 3],
                ),
                FlDotData(
                  getDotPainter: (spot, a, b, c) =>
                      FlDotCirclePainter(
                    radius: 4,
                    color: AppColors.accent,
                    strokeColor: Colors.white,
                    strokeWidth: 1.5,
                  ),
                ),
              ),
          ],
        ),
        lineBarsData: [
          LineChartBarData(
            spots: points,
            isCurved: true,
            barWidth: 2,
            color: color,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatPrice(double d) {
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

  static List<_Sample> _sample(List<Candle> candles, int maxPoints) {
    if (candles.length <= maxPoints) {
      return [
        for (final c in candles)
          _Sample(value: c.close.toDouble(), timestamp: c.timestamp),
      ];
    }
    final bucket = candles.length / maxPoints;
    final out = <_Sample>[];
    for (var i = 0; i < maxPoints; i++) {
      final start = (i * bucket).floor();
      final end = ((i + 1) * bucket).floor().clamp(start + 1, candles.length);
      var sum = 0.0;
      for (var j = start; j < end; j++) {
        sum += candles[j].close.toDouble();
      }
      // Use the midpoint candle's timestamp as the sample's time — it's a
      // fair label for a bucket-average close.
      final midIdx = (start + end) ~/ 2;
      out.add(
        _Sample(
          value: sum / (end - start),
          timestamp: candles[midIdx].timestamp,
        ),
      );
    }
    return out;
  }
}

class _Sample {
  const _Sample({required this.value, required this.timestamp});
  final double value;
  final DateTime timestamp;
}

class _RecentTradesSection extends ConsumerWidget {
  const _RecentTradesSection({required this.asset});
  final MarketAsset asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Non-tradable market-only assets never have trades data (their ID may
    // not map to a Binance symbol at all — USDC — or we simply choose not
    // to hammer /trades for every catalog entry). Bail early on those.
    if (asset.id == 'usd-coin') return const SizedBox.shrink();
    final async = ref.watch(recentTradesProvider(asset.id));
    return async.when(
      data: (trades) {
        if (trades.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              context.l10n.noData,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          );
        }
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(16),
          ),
          child: RecentTradesTape(
            trades: trades.take(12).toList(growable: false),
            quoteSymbol: asset.quoteSymbol,
            baseSymbol: asset.baseSymbol,
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          context.l10n.noData,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ),
    );
  }
}
