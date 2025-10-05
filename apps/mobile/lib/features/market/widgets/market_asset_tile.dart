import 'package:decimal/decimal.dart';
import 'package:dex_app/features/market/market_models.dart';
import 'package:dex_app/features/market/widgets/sparkline_chart.dart';
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
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _Avatar(symbol: asset.baseSymbol),
          const SizedBox(width: 12),
          // Left: symbol + volume/tradable subtitle. Takes just enough width
          // for the label so the sparkline gets a stable 88px slot.
          SizedBox(
            width: 88,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  asset.baseSymbol,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  asset.tradable
                      ? context.l10n.tradable
                      : _formatVolume(asset.volume24hUsd, context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          // Sparkline sits in the middle of the row; fixed height so tiles
          // don't jitter while the /v1/sparklines call is still in flight.
          Expanded(
            child: SizedBox(
              height: 36,
              child: SparklineChart(points: asset.sparkline),
            ),
          ),
          const SizedBox(width: 12),
          // Right: price stacked over 24h % pill.
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${_formatPrice(asset.priceUsd)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: changeColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${positive ? '+' : ''}${_formatChange(asset.change24hPercent)}%',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: changeColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: content,
    );
  }

  /// Compact 24h volume: 3.2B / 812M / 4.1K. USDC's zero-volume placeholder
  /// falls through to "Vol —" so the row still says something legible.
  static String _formatVolume(Decimal value, BuildContext context) {
    final d = value.toDouble();
    if (d <= 0) return 'Vol —';
    if (d >= 1e9) return 'Vol \$${(d / 1e9).toStringAsFixed(2)}B';
    if (d >= 1e6) return 'Vol \$${(d / 1e6).toStringAsFixed(1)}M';
    if (d >= 1e3) return 'Vol \$${(d / 1e3).toStringAsFixed(1)}K';
    return 'Vol \$${d.toStringAsFixed(0)}';
  }

  /// Prices span 8 orders of magnitude in this catalog (BTC ~$97,000, PEPE
  /// ~$0.00001). Pick a decimal precision that keeps ~4 significant digits
  /// without printing "0.0000010283…".
  static String _formatPrice(Decimal value) {
    final d = value.toDouble();
    if (d >= 1000) return d.toStringAsFixed(2);
    if (d >= 1) return d.toStringAsFixed(3);
    if (d >= 0.01) return d.toStringAsFixed(4);
    if (d >= 0.0001) return d.toStringAsFixed(6);
    return d.toStringAsExponential(3);
  }

  static String _formatChange(Decimal value) {
    final s = value.toString();
    final dot = s.indexOf('.');
    if (dot >= 0 && s.length - dot - 1 > 2) return s.substring(0, dot + 3);
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
      case 'BNB':
        return const [Color(0xFFF3BA2F), Color(0xFFFBBF24)];
      case 'XRP':
        return const [Color(0xFF23292F), Color(0xFF8B93A7)];
      case 'ADA':
        return const [Color(0xFF0033AD), Color(0xFF00E5FF)];
      case 'AVAX':
        return const [Color(0xFFE84142), Color(0xFFFBBF24)];
      case 'TON':
        return const [Color(0xFF0088CC), Color(0xFF00E5FF)];
      case 'SUI':
        return const [Color(0xFF4DA2FF), Color(0xFF00E5FF)];
      case 'APT':
        return const [Color(0xFF23292F), Color(0xFF14F195)];
      case 'ARB':
        return const [Color(0xFF28A0F0), Color(0xFF00E5FF)];
      case 'OP':
        return const [Color(0xFFFF0420), Color(0xFFF43F5E)];
      case 'MATIC':
        return const [Color(0xFF8247E5), Color(0xFFA855F7)];
      case 'LINK':
        return const [Color(0xFF2A5ADA), Color(0xFF00E5FF)];
      case 'UNI':
        return const [Color(0xFFFF007A), Color(0xFFA855F7)];
      case 'AAVE':
        return const [Color(0xFFB6509E), Color(0xFF2EBAC6)];
      case 'DOGE':
        return const [Color(0xFFC2A633), Color(0xFFFBBF24)];
      case 'SHIB':
        return const [Color(0xFFFFA409), Color(0xFFF43F5E)];
      case 'PEPE':
        return const [Color(0xFF10D876), Color(0xFF14F195)];
      case 'BONK':
        return const [Color(0xFFFF6B00), Color(0xFFFBBF24)];
      default:
        return const [AppColors.gradientStart, AppColors.gradientEnd];
    }
  }
}
