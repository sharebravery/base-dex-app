import 'package:dex_app/core/web3/base_tokens.dart';
import 'package:dex_app/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Visualizes the swap path returned by the aggregator:
///
///     [ETH] ─── Uniswap_V3 ───▶ [pool] ─── Aerodrome ───▶ [USDC]
///
/// Each hop label from `routeLabels` becomes a pill between two nodes. The
/// first node is the sell token, the last is the buy token, and any
/// intermediate pools are anonymous dots. Two-hop swaps get one dot; single
/// hops render as sell → pill → buy.
class RouteVisualization extends StatelessWidget {
  const RouteVisualization({
    required this.sellToken,
    required this.buyToken,
    required this.hopLabels,
    super.key,
  });

  final TokenInfo sellToken;
  final TokenInfo buyToken;
  final List<String> hopLabels;

  @override
  Widget build(BuildContext context) {
    if (hopLabels.isEmpty) return const SizedBox.shrink();

    // Node count = number of hop labels + 1 (each hop connects two nodes).
    final nodes = <_Node>[
      _Node.token(symbol: sellToken.symbol),
      for (var i = 0; i < hopLabels.length - 1; i++) const _Node.pool(),
      _Node.token(symbol: buyToken.symbol),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var i = 0; i < nodes.length; i++) ...[
            _NodeChip(node: nodes[i]),
            if (i != nodes.length - 1) _Hop(label: hopLabels[i]),
          ],
        ],
      ),
    );
  }
}

class _Node {
  const _Node.token({required this.symbol}) : isPool = false;
  const _Node.pool()
      : symbol = null,
        isPool = true;

  final String? symbol;
  final bool isPool;
}

class _NodeChip extends StatelessWidget {
  const _NodeChip({required this.node});
  final _Node node;

  @override
  Widget build(BuildContext context) {
    if (node.isPool) {
      return Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.textMuted,
          border: Border.all(color: AppColors.border, width: 2),
        ),
      );
    }
    final symbol = node.symbol!;
    final palette = _paletteFor(symbol);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: palette,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              symbol.characters.first,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            symbol,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }

  static List<Color> _paletteFor(String symbol) {
    switch (symbol.toUpperCase()) {
      case 'ETH':
        return const [Color(0xFF627EEA), Color(0xFF00E5FF)];
      case 'USDC':
        return const [Color(0xFF2775CA), Color(0xFF00E5FF)];
    }
    return const [AppColors.gradientStart, AppColors.gradientEnd];
  }
}

class _Hop extends StatelessWidget {
  const _Hop({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 1,
          color: AppColors.border,
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.35),
            ),
          ),
          child: Text(
            label.replaceAll('_', ' '),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        const Icon(
          Icons.arrow_forward,
          size: 12,
          color: AppColors.textMuted,
        ),
      ],
    );
  }
}
