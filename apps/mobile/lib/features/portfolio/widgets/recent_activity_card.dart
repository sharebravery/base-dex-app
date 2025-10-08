import 'package:dex_app/core/widgets/glass_card.dart';
import 'package:dex_app/features/trade/pending_transaction.dart';
import 'package:dex_app/l10n/l10n_extension.dart';
import 'package:dex_app/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Compact "Recent activity" card summarizing the three most recent pending
/// transactions. Renders a "View all →" affordance leading to the full
/// Activity screen. If there's nothing to show, we render a soft empty
/// state so the section slot doesn't collapse and re-jitter the layout.
class RecentActivityCard extends StatelessWidget {
  const RecentActivityCard({
    required this.items,
    required this.onViewAll,
    super.key,
  });

  final List<PendingTransaction> items;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final visible = items.take(3).toList(growable: false);

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.recentActivity,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                TextButton(
                  onPressed: onViewAll,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 0,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(l10n.viewAll),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 12,
              ),
              child: Text(
                l10n.noActivity,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            )
          else
            for (final it in visible) _ActivityRow(item: it),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.item});

  final PendingTransaction item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            alignment: Alignment.center,
            child: Icon(
              _iconFor(item.operation),
              size: 18,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _labelFor(context, item.operation, item.symbol),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _shortHash(item.txHash),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              context.l10n.pending,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  static IconData _iconFor(PendingOperation op) => switch (op) {
        PendingOperation.approve => Icons.check_circle_outline,
        PendingOperation.swap => Icons.swap_horiz,
        PendingOperation.withdraw => Icons.upload,
      };

  static String _labelFor(
    BuildContext context,
    PendingOperation op,
    String symbol,
  ) {
    final l10n = context.l10n;
    return switch (op) {
      PendingOperation.approve => l10n.approveToken(symbol),
      PendingOperation.swap => '${l10n.swap} · $symbol',
      PendingOperation.withdraw => '${l10n.withdraw} · $symbol',
    };
  }

  static String _shortHash(String h) => h.length > 12
      ? '${h.substring(0, 6)}…${h.substring(h.length - 4)}'
      : h;
}
