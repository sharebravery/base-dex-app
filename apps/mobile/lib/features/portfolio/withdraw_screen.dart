import 'package:dex_app/core/security/biometric_gate.dart';
import 'package:dex_app/core/web3/base_tokens.dart';
import 'package:dex_app/features/auth/wallet_service.dart';
import 'package:dex_app/features/portfolio/withdraw_controller.dart';
import 'package:dex_app/features/trade/pending_transaction.dart';
import 'package:dex_app/features/trade/pending_transaction_store.dart';
import 'package:dex_app/features/trade/trade_executor.dart';
import 'package:dex_app/features/trade/transaction_service.dart';
import 'package:dex_app/features/trade/transaction_timeline.dart';
import 'package:dex_app/l10n/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Withdraw ETH or USDC to a user-provided Base address.
///
/// Constructor-injected dependencies keep this widget bootstrap-agnostic. A
/// later task wires providers/routes; the widget itself never constructs a
/// second `BiometricGate`, `TransactionService`, or `PendingTransactionStore`.
class WithdrawScreen extends HookWidget {
  const WithdrawScreen({
    required this.controller,
    required this.biometric,
    required this.transactions,
    required this.wallet,
    required this.chain,
    required this.store,
    required this.walletAddress,
    required this.token,
    required this.currentBalance,
    super.key,
  });

  final WithdrawController controller;
  final BiometricGate biometric;
  final TransactionService transactions;
  final WalletService wallet;
  final ChainGateway chain;
  final PendingTransactionStore store;
  final String walletAddress;
  final TokenInfo token;
  final BigInt currentBalance;

  @override
  Widget build(BuildContext context) {
    assert(
      token.symbol == BaseTokens.eth.symbol || token.symbol == BaseTokens.usdc.symbol,
      'WithdrawScreen supports ETH and USDC only',
    );
    if (token.symbol != BaseTokens.eth.symbol &&
        token.symbol != BaseTokens.usdc.symbol) {
      throw ArgumentError.value(
        token.symbol,
        'token',
        'WithdrawScreen supports ETH and USDC only',
      );
    }

    final addressField = useTextEditingController();
    final amountField = useTextEditingController();
    final errorCode = useState<String?>(null);
    final stage = useState<TransactionStage>(TransactionStage.preparing);
    final txHash = useState<String?>(null);

    Future<void> onConfirm() async {
      errorCode.value = null;
      final validation = controller.validate(
        address: addressField.text.trim(),
        amount: amountField.text.trim(),
        decimals: token.decimals,
      );
      if (validation != null) {
        errorCode.value = validation;
        return;
      }

      stage.value = TransactionStage.authenticating;
      final authenticated = await biometric.authenticate('Confirm withdrawal');
      if (!authenticated) {
        stage.value = TransactionStage.preparing;
        return;
      }

      final rawAmount = controller.toRawAmount(amountField.text.trim(), token.decimals);
      final destination = addressField.text.trim();

      try {
        stage.value = TransactionStage.swapping;
        final hash = token.isNative
            ? await transactions.sendNative(
                owner: walletAddress,
                to: destination,
                amount: rawAmount,
              )
            : await transactions.sendErc20Transfer(
                owner: walletAddress,
                token: token.address,
                to: destination,
                amount: rawAmount,
              );

        await store.save(
          PendingTransaction(
            txHash: hash,
            walletAddress: walletAddress,
            operation: PendingOperation.withdraw,
            symbol: token.symbol,
            createdAt: DateTime.now(),
          ),
        );
        txHash.value = hash;
        stage.value = TransactionStage.submitted;
      } on Object {
        stage.value = TransactionStage.failed;
        errorCode.value = 'submission_failed';
      }
    }

    String? errorText() => switch (errorCode.value) {
          'invalid_address' => context.l10n.invalidAddress,
          'invalid_amount' => context.l10n.invalidAmount,
          'too_many_decimals' => context.l10n.tooManyDecimals,
          'submission_failed' => context.l10n.submissionFailed,
          _ => null,
        };

    final showTimeline = stage.value != TransactionStage.preparing;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.withdraw)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('${token.symbol}: $currentBalance'),
              const SizedBox(height: 16),
              TextField(
                controller: addressField,
                onChanged: (_) => errorCode.value = null,
                decoration: InputDecoration(
                  labelText: context.l10n.recipientAddress,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountField,
                onChanged: (_) => errorCode.value = null,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: context.l10n.amount),
              ),
              if (errorText() != null) ...[
                const SizedBox(height: 8),
                Text(
                  errorText()!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: showTimeline ? null : onConfirm,
                child: Text(context.l10n.confirmWithdraw),
              ),
              if (showTimeline) ...[
                const SizedBox(height: 24),
                TransactionTimeline(stage: stage.value),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
