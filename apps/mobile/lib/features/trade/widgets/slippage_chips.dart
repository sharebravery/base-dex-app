import 'package:dex_app/l10n/l10n_extension.dart';
import 'package:dex_app/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Preset slippage chips in basis points. 10 / 50 / 100 / 300 covers the
/// range every wallet ships as their default preset — deep enough for
/// stablecoin swaps, tight enough that a fat-finger meme trade still trips
/// the impact warning.
const _presetsBps = [10, 50, 100, 300];

class SlippageChips extends StatelessWidget {
  const SlippageChips({
    required this.slippageBps,
    required this.onChanged,
    super.key,
  });

  final int slippageBps;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          l10n.slippageTolerance,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const Spacer(),
        for (final bps in _presetsBps) ...[
          _Chip(
            label: _formatBps(bps),
            selected: bps == slippageBps,
            onTap: () => onChanged(bps),
          ),
          const SizedBox(width: 6),
        ],
        _Chip(
          label: '${_formatBps(slippageBps)}★',
          selected: !_presetsBps.contains(slippageBps),
          onTap: () {}, // no-op; custom entry could open a dialog later
          faded: true,
        ),
      ],
    );
  }

  static String _formatBps(int bps) {
    // 10 → "0.1%", 100 → "1%", 300 → "3%". Trim trailing zeros for looks.
    final pct = bps / 100;
    if (pct >= 1) return '${pct.toStringAsFixed(pct == pct.roundToDouble() ? 0 : 2)}%';
    return '${pct.toStringAsFixed(1)}%';
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.faded = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool faded;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.14)
              : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: selected
                    ? AppColors.accent
                    : (faded ? AppColors.textMuted : AppColors.textPrimary),
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}
