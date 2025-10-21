import 'package:dex_app/core/web3/base_tokens.dart';
import 'package:dex_app/features/auth/auth_providers.dart';
import 'package:dex_app/features/trade/confirmation_sheet.dart';
import 'package:dex_app/features/trade/trade_providers.dart';
import 'package:dex_app/features/trade/trade_screen.dart';
import 'package:dex_app/l10n/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TradeScreenWired extends ConsumerWidget {
  const TradeScreenWired({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(tradeControllerProvider);
    final session = ref.watch(activeWalletSessionProvider);
    return TradeScreen(
      controller: controller,
      taker: session?.address ?? '0x0000000000000000000000000000000000000000',
      onConfirm: () => _confirm(context, ref),
    );
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final quote = ref.read(tradeControllerProvider).state.quote;
    if (quote == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => ConfirmationSheet(
        quote: quote,
        sellToken: BaseTokens.usdc,
        currentAllowance: BigInt.zero,
        onConfirm: () async {
          Navigator.pop(sheetContext);
          // Route-preview quotes carry no calldata — we deliberately never
          // reach TradeExecutor.execute. Surface that to the user instead of
          // simulating a fake broadcast animation.
          if (quote.transactionData == null) {
            messenger.showSnackBar(
              SnackBar(content: Text(l10n.demoConfirmed)),
            );
            return;
          }
          try {
            final executor = ref.read(tradeExecutorProvider);
            await executor.execute(quote);
            messenger.showSnackBar(
              SnackBar(content: Text(l10n.transactionSubmitted)),
            );
          } catch (e) {
            messenger.showSnackBar(
              SnackBar(content: Text('${l10n.submissionFailed}: $e')),
            );
          }
        },
      ),
    );
  }
}
