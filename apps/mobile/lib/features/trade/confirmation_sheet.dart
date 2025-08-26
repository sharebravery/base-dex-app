import 'package:dex_app/core/web3/base_tokens.dart';
import 'package:dex_app/features/trade/trade_models.dart';
import 'package:dex_app/l10n/l10n_extension.dart';
import 'package:flutter/material.dart';

class ConfirmationSheet extends StatelessWidget {
  const ConfirmationSheet({
    required this.quote,
    required this.sellToken,
    required this.currentAllowance,
    this.onConfirm,
    super.key,
  });

  final SwapQuote quote;
  final TokenInfo sellToken;
  final BigInt currentAllowance;
  final VoidCallback? onConfirm;

  bool get _needsApproval =>
      quote.allowanceTarget != null && currentAllowance < quote.sellAmount;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final quoteFresh = quote.isFreshAt(DateTime.now());

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _row(l10n.pay, '${quote.sellAmount}'),
            _row(l10n.receive, '${quote.buyAmount}'),
            _row(l10n.minimumReceived, '${quote.minBuyAmount}'),
            _row(l10n.networkFee, '${quote.networkFee}'),
            _row(l10n.slippage, '${_slippageBps(quote)} bps'),
            _row(l10n.route, quote.routeLabels.join(' > ')),
            if (quote.allowanceTarget != null)
              _row(l10n.spender, quote.allowanceTarget!),
            _row(l10n.chain, l10n.baseChain),
            _row(l10n.destination, quote.transactionTo),
            if (_needsApproval) ...[
              const SizedBox(height: 12),
              _row(l10n.approveToken(sellToken.symbol), '${quote.sellAmount}'),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: quoteFresh ? onConfirm : null,
              child: Text(l10n.confirm),
            ),
          ],
        ),
      ),
    );
  }

  int _slippageBps(SwapQuote q) {
    if (q.buyAmount == BigInt.zero) return 0;
    final diff = q.buyAmount - q.minBuyAmount;
    return (diff * BigInt.from(10000) ~/ q.buyAmount).toInt();
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
