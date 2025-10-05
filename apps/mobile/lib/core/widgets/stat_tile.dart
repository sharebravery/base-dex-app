import 'package:dex_app/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Compact label/value tile used in the Market hero row, Pair Detail stats
/// grid, and Portfolio header. Keeps values in tabular figures so they
/// don't shift width as they update.
class StatTile extends StatelessWidget {
  const StatTile({
    required this.label,
    required this.value,
    this.delta,
    this.deltaPositive,
    this.icon,
    super.key,
  });

  final String label;
  final String value;
  final String? delta;
  final bool? deltaPositive;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.labelSmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (delta != null) ...[
          const SizedBox(height: 4),
          Text(
            delta!,
            style: theme.textTheme.labelSmall?.copyWith(
              color: deltaPositive == null
                  ? AppColors.textSecondary
                  : (deltaPositive! ? AppColors.positive : AppColors.negative),
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ],
    );
  }
}

/// Positive/negative pill for a delta or a status. Auto-colored via
/// [positive] — pass a formatted string ("+2.41%", "-0.82%").
class DeltaPill extends StatelessWidget {
  const DeltaPill({required this.text, required this.positive, super.key});

  final String text;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final color = positive ? AppColors.positive : AppColors.negative;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            positive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
