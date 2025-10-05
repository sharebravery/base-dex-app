import 'package:dex_app/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Round token badge painted with a symbol-specific gradient. Used everywhere
/// a token is referenced (Market rows, Swap card sides, Portfolio holdings,
/// Confirmation sheet, etc.). Keeps a single source of truth for token colors.
class TokenIcon extends StatelessWidget {
  const TokenIcon({required this.symbol, this.size = 40, super.key});

  final String symbol;
  final double size;

  static List<Color> paletteFor(String symbol) {
    switch (symbol.toUpperCase()) {
      case 'ETH':
        return const [Color(0xFF627EEA), Color(0xFF00E5FF)];
      case 'BTC':
        return const [Color(0xFFF7931A), Color(0xFFFBBF24)];
      case 'SOL':
        return const [Color(0xFF14F195), Color(0xFF9945FF)];
      case 'USDC':
        return const [Color(0xFF2775CA), Color(0xFF00E5FF)];
      case 'USDT':
        return const [Color(0xFF26A17B), Color(0xFF10D876)];
      case 'DEGEN':
        return const [Color(0xFFA855F7), Color(0xFFF43F5E)];
      case 'AERO':
        return const [Color(0xFF00E5FF), Color(0xFF10D876)];
      default:
        return const [AppColors.gradientStart, AppColors.gradientEnd];
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = paletteFor(symbol);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.35),
            blurRadius: size * 0.4,
            offset: Offset(0, size * 0.15),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        symbol.characters.first,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: Colors.white,
          fontSize: size * 0.42,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
