import 'package:decimal/decimal.dart';
import 'package:dex_app/features/market/market_models.dart';
import 'package:dex_app/l10n/l10n_extension.dart';
import 'package:dex_app/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Newest-first list of recent trades. Rows are compact (28 px) so ~10
/// entries fit in a mobile viewport without scrolling. The tape does NOT
/// scroll itself — the caller decides how tall it is.
///
/// `isBuyerMaker` follows Binance semantics: true = seller was aggressive
/// (red row), false = buyer was aggressive (green row).
class RecentTradesTape extends StatelessWidget {
  const RecentTradesTape({
    required this.trades,
    required this.quoteSymbol,
    required this.baseSymbol,
    super.key,
  });

  final List<RecentTrade> trades;
  final String quoteSymbol;
  final String baseSymbol;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header row: monospaced-feel labels above their columns.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  l10n.tradePrice,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  '${l10n.tradeAmount} ($baseSymbol)',
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  l10n.tradeTime,
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        for (final t in trades) _TradeRow(trade: t),
      ],
    );
  }
}

class _TradeRow extends StatelessWidget {
  const _TradeRow({required this.trade});

  final RecentTrade trade;

  @override
  Widget build(BuildContext context) {
    // Binance: isBuyerMaker=true means seller was aggressive → red.
    final aggressiveBuy = !trade.isBuyerMaker;
    final color = aggressiveBuy ? AppColors.positive : AppColors.negative;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              _price(trade.price),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              _qty(trade.qty),
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              _time(trade.timestamp),
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
            ),
          ),
        ],
      ),
    );
  }

  static String _price(Decimal value) {
    final d = value.toDouble();
    if (d >= 1000) return d.toStringAsFixed(2);
    if (d >= 1) return d.toStringAsFixed(3);
    if (d >= 0.01) return d.toStringAsFixed(4);
    if (d >= 0.0001) return d.toStringAsFixed(6);
    return d.toStringAsExponential(2);
  }

  static String _qty(Decimal value) {
    final d = value.toDouble();
    if (d >= 1000) return d.toStringAsFixed(1);
    if (d >= 1) return d.toStringAsFixed(3);
    if (d >= 0.001) return d.toStringAsFixed(4);
    return d.toStringAsExponential(2);
  }

  /// HH:MM:SS in the local timezone. Deterministic — safe for goldens.
  static String _time(DateTime t) {
    final local = t.toLocal();
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${pad(local.hour)}:${pad(local.minute)}:${pad(local.second)}';
  }
}
