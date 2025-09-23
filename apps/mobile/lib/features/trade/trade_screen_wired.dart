import 'package:dex_app/core/web3/base_tokens.dart';
import 'package:dex_app/features/auth/auth_providers.dart';
import 'package:dex_app/features/trade/confirmation_sheet.dart';
import 'package:dex_app/features/trade/trade_providers.dart';
import 'package:dex_app/features/trade/trade_screen.dart';
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
    final executor = ref.read(tradeExecutorProvider);
    final messenger = ScaffoldMessenger.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => ConfirmationSheet(
        quote: quote,
        sellToken: BaseTokens.usdc,
        currentAllowance: BigInt.zero,
        onConfirm: () async {
          Navigator.pop(sheetContext);
          try {
            await executor.execute(quote);
            messenger.showSnackBar(
              const SnackBar(content: Text('Trade executed (demo)')),
            );
          } catch (e) {
            messenger.showSnackBar(
              SnackBar(content: Text('Trade failed: $e')),
            );
          }
        },
      ),
    );
  }
}
