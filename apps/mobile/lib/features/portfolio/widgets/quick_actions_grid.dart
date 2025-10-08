import 'package:dex_app/core/widgets/glass_card.dart';
import 'package:dex_app/l10n/l10n_extension.dart';
import 'package:dex_app/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// 2×2 grid of primary portfolio actions. Deliberately taller than a plain
/// button row — each cell has room for an icon avatar, a label, and a
/// one-line subtitle, so the section carries visual weight below the hero.
class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({
    required this.onDeposit,
    required this.onWithdraw,
    required this.onSwap,
    required this.onActivity,
    super.key,
  });

  final VoidCallback onDeposit;
  final VoidCallback onWithdraw;
  final VoidCallback onSwap;
  final VoidCallback onActivity;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = <_Action>[
      _Action(
        icon: Icons.download_rounded,
        title: l10n.deposit,
        subtitle: l10n.quickDepositSub,
        onTap: onDeposit,
        gradient: const [Color(0xFF00E5FF), Color(0xFF2775CA)],
      ),
      _Action(
        icon: Icons.upload_rounded,
        title: l10n.withdraw,
        subtitle: l10n.quickWithdrawSub,
        onTap: onWithdraw,
        gradient: const [Color(0xFFA855F7), Color(0xFF6366F1)],
      ),
      _Action(
        icon: Icons.swap_horiz_rounded,
        title: l10n.swap,
        subtitle: l10n.quickSwapSub,
        onTap: onSwap,
        gradient: const [Color(0xFF10D876), Color(0xFF14F195)],
      ),
      _Action(
        icon: Icons.history_rounded,
        title: l10n.activity,
        subtitle: l10n.quickActivitySub,
        onTap: onActivity,
        gradient: const [Color(0xFFFBBF24), Color(0xFFF7931A)],
      ),
    ];

    return GridView.count(
      // These four buttons live inside a CustomScrollView slivers list, so
      // the grid itself must not scroll or take unbounded height.
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.4,
      children: [
        for (final it in items) _ActionCell(action: it),
      ],
    );
  }
}

class _Action {
  const _Action({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.gradient,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final List<Color> gradient;
}

class _ActionCell extends StatelessWidget {
  const _ActionCell({required this.action});
  final _Action action;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: action.onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: action.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(action.icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  action.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  action.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
