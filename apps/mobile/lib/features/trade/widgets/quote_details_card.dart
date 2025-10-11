import 'package:decimal/decimal.dart';
import 'package:dex_app/core/web3/base_tokens.dart';
import 'package:dex_app/features/trade/trade_models.dart';
import 'package:dex_app/features/trade/widgets/route_visualization.dart';
import 'package:dex_app/l10n/l10n_extension.dart';
import 'package:dex_app/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Quote breakdown card. Renders only after `getQuote()` returns — if the
/// caller has just a `SwapPrice`, they should show the smaller
/// [PriceHintTile] variant instead so the layout doesn't jump.
class QuoteDetailsCard extends StatelessWidget {
  const QuoteDetailsCard({
    required this.quote,
    required this.sellToken,
    required this.buyToken,
    super.key,
  });

  final SwapQuote quote;
  final TokenInfo sellToken;
  final TokenInfo buyToken;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rate = _computeRate(quote, sellToken, buyToken);
    final minReceived =
        _toDecimalUnits(quote.minBuyAmount, buyToken.decimals);
    final gas = _toDecimalUnits(quote.gas * quote.gasPrice, 18);
    final networkFee = _toDecimalUnits(quote.networkFee, 18);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Row(
            label: l10n.rate,
            value: '1 ${sellToken.symbol} ≈ ${_trim(rate)} ${buyToken.symbol}',
          ),
          _Row(
            label: l10n.minimumReceived,
            value: '${_trim(minReceived)} ${buyToken.symbol}',
          ),
          _Row(
            label: l10n.priceImpact,
            value: '<0.10%',
            valueColor: AppColors.positive,
          ),
          _Row(
            label: l10n.gasEstimate,
            value: '${_trim(gas)} ETH',
          ),
          _Row(
            label: l10n.networkFee,
            value: '${_trim(networkFee)} ETH',
          ),
          const SizedBox(height: 10),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                l10n.route,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const Spacer(),
              Text(
                l10n.routeVia('KyberSwap'),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          RouteVisualization(
            sellToken: sellToken,
            buyToken: buyToken,
            hopLabels: quote.routeLabels,
          ),
        ],
      ),
    );
  }

  static Decimal _computeRate(
    SwapQuote quote,
    TokenInfo sellToken,
    TokenInfo buyToken,
  ) {
    final sell = _toDecimalUnits(quote.sellAmount, sellToken.decimals);
    final buy = _toDecimalUnits(quote.buyAmount, buyToken.decimals);
    if (sell <= Decimal.zero) return Decimal.zero;
    return (buy / sell).toDecimal(scaleOnInfinitePrecision: 10);
  }

  static Decimal _toDecimalUnits(BigInt raw, int decimals) {
    final base = BigInt.from(10).pow(decimals);
    return (Decimal.parse(raw.toString()) /
            Decimal.parse(base.toString()))
        .toDecimal(scaleOnInfinitePrecision: 18);
  }

  static String _trim(Decimal v) {
    final s = v.toString();
    final dot = s.indexOf('.');
    if (dot < 0) return s;
    // Show 6 places max — small enough to be useful for both ETH and USDC
    // scales, wide enough for meaningful stablecoin drift.
    return s.length - dot > 7 ? s.substring(0, dot + 7) : s;
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: valueColor ?? AppColors.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
          ),
        ],
      ),
    );
  }
}
