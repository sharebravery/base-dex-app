import 'package:decimal/decimal.dart';
import 'package:dex_app/features/market/market_models.dart';
import 'package:dex_app/l10n/l10n_extension.dart';
import 'package:dex_app/theme/app_colors.dart';
import 'package:flutter/material.dart';
class MarketAssetTile extends StatelessWidget {
  const MarketAssetTile({required this.asset, this.onTap, super.key});

  final MarketAsset asset;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final positive = asset.change24hPercent >= Decimal.zero;
    final changeColor = positive ? AppColors.positive : AppColors.negative;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: _Avatar(symbol: asset.baseSymbol),
      title: Text(
        asset.baseSymbol,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Text(
        asset.tradable ? context.l10n.tradable : context.l10n.marketDataOnly,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '\$${_format(asset.priceUsd)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '${positive ? '+' : ''}${_format(asset.change24hPercent)}%',
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: changeColor),
          ),
        ],
      ),
    );
  }

  String _format(Decimal value) {
    final s = value.toString();
    // Trim to 2 decimals if there are more.
    final dot = s.indexOf('.');
    if (dot >= 0 && s.length - dot - 1 > 2) {
      return s.substring(0, dot + 3);
    }
    return s;
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.symbol});
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final colors = _paletteFor(symbol);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        symbol.characters.first,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: Colors.white,
          fontSize: 16,
        ),
      ),
    );
  }

  List<Color> _paletteFor(String s) {
    switch (s.toUpperCase()) {
      case 'ETH':
        return const [Color(0xFF627EEA), Color(0xFF00E5FF)];
      case 'BTC':
        return const [Color(0xFFF7931A), Color(0xFFFBBF24)];
      case 'SOL':
        return const [Color(0xFF14F195), Color(0xFF9945FF)];
      case 'USDC':
        return const [Color(0xFF2775CA), Color(0xFF00E5FF)];
      default:
        return const [AppColors.gradientStart, AppColors.gradientEnd];
    }
  }
}
