import 'package:dex_app/core/web3/base_tokens.dart';
import 'package:dex_app/features/trade/trade_controller.dart';
import 'package:dex_app/l10n/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class TradeScreen extends HookWidget {
  const TradeScreen({
    required this.controller,
    required this.taker,
    required this.onConfirm,
    super.key,
  });

  final TradeController controller;
  final String taker;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final amountController = useTextEditingController();
    useEffect(() {
      void listener() {
        controller.updateAmount(
          amountText: amountController.text,
          sellToken: BaseTokens.usdc,
          buyToken: BaseTokens.eth,
          taker: taker,
        );
      }
      amountController.addListener(listener);
      return () => amountController.removeListener(listener);
    }, [amountController, controller, taker]);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final state = controller.state;
        final quoteFresh =
            state.quote?.isFreshAt(DateTime.now()) == true;
        final form = ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: context.l10n.usdcBaseUnits,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                state.loadingPrice
                    ? context.l10n.loadingPrice
                    : state.price == null
                        ? context.l10n.enterAmount
                        : '${context.l10n.indicative}: ${state.price!.buyAmount}',
              ),
              if (state.errorCode != null) ...[
                const SizedBox(height: 8),
                Text(state.errorCode!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: state.request == null || state.loadingQuote
                    ? null
                    : controller.review,
                child: Text(state.loadingQuote ? context.l10n.loadingQuote : context.l10n.review),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: quoteFresh ? onConfirm : null,
                child: Text(context.l10n.confirmSwap),
              ),
            ],
          ),
        );

        return Scaffold(
          appBar: AppBar(title: Text('${BaseTokens.eth.symbol} / ${BaseTokens.usdc.symbol}')),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 840) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: form,
                  );
                }
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      const Expanded(child: Placeholder()),
                      const SizedBox(width: 24),
                      form,
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
