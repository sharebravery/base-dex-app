import 'package:dex_app/features/trade/trade_executor.dart';
import 'package:dex_app/l10n/l10n_extension.dart';
import 'package:flutter/material.dart';

class TransactionTimeline extends StatelessWidget {
  const TransactionTimeline({required this.stage, super.key});

  final TransactionStage stage;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final steps = <String>[];
    switch (stage) {
      case TransactionStage.preparing:
        break;
      case TransactionStage.authenticating:
        steps.add(l10n.authenticating);
      case TransactionStage.approving:
        steps.add(l10n.authenticating);
        steps.add(l10n.approving);
      case TransactionStage.approvalSubmitted:
        steps.add(l10n.authenticating);
        steps.add(l10n.approving);
        steps.add(l10n.transactionSubmitted);
      case TransactionStage.swapping:
        steps.add(l10n.authenticating);
        steps.add(l10n.approving);
        steps.add(l10n.swapping);
      case TransactionStage.submitted:
        steps.add(l10n.authenticating);
        steps.add(l10n.swapping);
        steps.add(l10n.transactionSubmitted);
      case TransactionStage.confirmed:
        steps.add(l10n.authenticating);
        steps.add(l10n.swapping);
        steps.add(l10n.transactionConfirmed);
      case TransactionStage.failed:
        steps.add(l10n.transactionFailed);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final label in steps)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.check, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(label)),
              ],
            ),
          ),
      ],
    );
  }
}
