import 'package:dex_app/core/widgets/glass_card.dart';
import 'package:dex_app/features/portfolio/activity_models.dart';
import 'package:dex_app/features/trade/pending_transaction_store.dart';
import 'package:dex_app/features/trade/trade_providers.dart';
import 'package:dex_app/l10n/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(pendingTransactionStoreProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.activity)),
      body: FutureBuilder<List<ActivityItem>>(
        future: _load(store),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data ?? const [];
          if (items.isEmpty) {
            return Center(
              child: Text(
                context.l10n.noActivity,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final it = items[i];
              return GlassCard(
                child: Row(
                  children: [
                    Icon(_iconFor(it.type)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            it.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _shortHash(it.txHash),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    _statusChip(context, it.status),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<List<ActivityItem>> _load(PendingTransactionStore store) async {
    final pending = await store.loadAll();
    return pending
        .map(
          (p) => ActivityItem(
            type: ActivityType.swap,
            status: ActivityStatus.pending,
            title: p.symbol,
            txHash: p.txHash,
            timestamp: p.createdAt,
          ),
        )
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  IconData _iconFor(ActivityType t) => switch (t) {
        ActivityType.swap => Icons.swap_horiz,
        ActivityType.approve => Icons.check_circle_outline,
        ActivityType.deposit => Icons.download,
        ActivityType.withdraw => Icons.upload,
      };

  String _shortHash(String h) => h.length > 12
      ? '${h.substring(0, 6)}…${h.substring(h.length - 4)}'
      : h;

  Widget _statusChip(BuildContext c, ActivityStatus s) {
    final label = switch (s) {
      ActivityStatus.pending => c.l10n.pending,
      ActivityStatus.confirmed => c.l10n.confirmed,
      ActivityStatus.failed => c.l10n.failed,
    };
    return Chip(label: Text(label));
  }
}
