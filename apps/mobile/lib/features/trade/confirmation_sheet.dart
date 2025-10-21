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
    // Route-preview only (KyberSwap `/routes` without follow-up `/route/build`)
    // — no calldata means we can't broadcast. Surface that plainly so no one
    // reads the destination row as "your funds go here".
    final demoOnly = quote.transactionData == null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (demoOnly) ...[
              _DemoBanner(text: l10n.demoNotBroadcast),
              const SizedBox(height: 12),
            ],
            _row(l10n.pay, '${quote.sellAmount}'),
            _row(l10n.receive, '${quote.buyAmount}'),
            _row(l10n.minimumReceived, '${quote.minBuyAmount}'),
            _row(l10n.networkFee, '${quote.networkFee}'),
            _row(l10n.slippage, '${_slippageBps(quote)} bps'),
            _row(l10n.route, quote.routeLabels.join(' · ')),
            if (quote.allowanceTarget != null)
              _row(l10n.spender, _shortAddress(quote.allowanceTarget!)),
            _row(l10n.chain, l10n.baseChain),
            _row(l10n.destination, _shortAddress(quote.transactionTo)),
            if (_needsApproval) ...[
              const SizedBox(height: 12),
              _row(l10n.approveToken(sellToken.symbol), '${quote.sellAmount}'),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: quoteFresh ? onConfirm : null,
              child: Text(demoOnly ? l10n.confirmDemo : l10n.confirm),
            ),
          ],
        ),
      ),
    );
  }

  static String _shortAddress(String value) {
    if (!value.startsWith('0x') || value.length < 12) return value;
    return '${value.substring(0, 6)}…${value.substring(value.length - 4)}';
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

class _DemoBanner extends StatelessWidget {
  const _DemoBanner({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: scheme.tertiary.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: scheme.tertiary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onTertiaryContainer,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
