import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:dex_app/core/web3/base_tokens.dart';
import 'package:dex_app/features/trade/trade_controller.dart';
import 'package:dex_app/features/trade/trade_models.dart';
import 'package:dex_app/features/trade/widgets/quote_details_card.dart';
import 'package:dex_app/features/trade/widgets/slippage_chips.dart';
import 'package:dex_app/features/trade/widgets/swap_amount_field.dart';
import 'package:dex_app/l10n/l10n_extension.dart';
import 'package:dex_app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Trade screen shell. All state lives in [TradeController]; this widget
/// just wires the input controller to `updateAmount()` and renders the
/// state each notify.
///
/// The UI is intentionally rich even though only USDC → ETH is really
/// tradable on Base right now — the visuals reflect what a full-featured
/// swap flow looks like, which is what the "demo" tag is for.
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
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              '${BaseTokens.usdc.symbol} → ${BaseTokens.eth.symbol}',
            ),
            actions: const [_DemoBadge()],
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final banner = _DemoBanner();
                final form = _Form(
                  controller: controller,
                  state: controller.state,
                  amountController: amountController,
                  onConfirm: onConfirm,
                );
                if (constraints.maxWidth < 840) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [banner, const SizedBox(height: 12), form],
                    ),
                  );
                }
                // Wide layout mirrors the mobile column with an empty gutter on
                // the left so the form doesn't stretch to unreadable widths.
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(child: SizedBox()),
                      const SizedBox(width: 24),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [banner, const SizedBox(height: 12), form],
                        ),
                      ),
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

class _DemoBadge extends StatelessWidget {
  const _DemoBadge();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Chip(
        visualDensity: VisualDensity.compact,
        label: Text(context.l10n.demoBadge),
        padding: EdgeInsets.zero,
      ),
    );
  }
}

class _DemoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            size: 16,
            color: AppColors.warning,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.demoTradeBanner,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.warning,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Form extends HookWidget {
  const _Form({
    required this.controller,
    required this.state,
    required this.amountController,
    required this.onConfirm,
  });

  final TradeController controller;
  final TradeState state;
  final TextEditingController amountController;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    // Tick every second so the "fresh for X" countdown updates without
    // needing to touch controller state.
    final now = useState(DateTime.now());
    useEffect(() {
      final timer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => now.value = DateTime.now(),
      );
      return timer.cancel;
    }, const []);

    final quoteFresh = state.quote?.isFreshAt(now.value) == true;
    final buyDecimalString = _buyDecimalStringFor(state);
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwapAmountField.pay(
          token: BaseTokens.usdc,
          controller: amountController,
          onChanged: (_) {}, // TradeController listens via useEffect
          context: context,
          approxUsd: _sellApproxUsd(state),
        ),
        // Flip button — visual only; ETH/USDC in the demo only swaps in one
        // direction against the Kyber route we ship, but the affordance
        // sells "this is a real swap UI".
        _FlipDivider(onTap: () {}),
        SwapAmountField.receive(
          token: BaseTokens.eth,
          value: buyDecimalString,
          context: context,
          approxUsd: _buyApproxUsd(state),
          loading: state.loadingPrice,
        ),
        const SizedBox(height: 16),
        SlippageChips(
          slippageBps: state.slippageBps,
          onChanged: controller.setSlippageBps,
        ),
        const SizedBox(height: 16),
        if (state.errorCode != null)
          _ErrorBanner(text: l10n.priceUnavailable)
        else if (state.quote != null)
          QuoteDetailsCard(
            quote: state.quote!,
            sellToken: BaseTokens.usdc,
            buyToken: BaseTokens.eth,
          )
        else if (state.price != null || state.loadingPrice)
          _PriceHintTile(state: state),
        const SizedBox(height: 16),
        if (state.quote == null)
          FilledButton(
            onPressed: state.request == null || state.loadingQuote
                ? null
                : controller.review,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
            ),
            child: Text(
              state.loadingQuote ? l10n.loadingQuote : l10n.getQuote,
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _QuoteCountdown(quote: state.quote!, now: now.value),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: quoteFresh ? onConfirm : controller.review,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
                child: Text(
                  quoteFresh ? l10n.confirmSwap : l10n.quoteExpired,
                ),
              ),
            ],
          ),
      ],
    );
  }

  static String _buyDecimalStringFor(TradeState state) {
    final buy = state.quote?.buyAmount ?? state.price?.buyAmount;
    if (buy == null) return '0';
    return _toDecimal(buy, BaseTokens.eth.decimals);
  }

  static Decimal? _sellApproxUsd(TradeState state) {
    final sell = state.request?.sellAmount;
    if (sell == null) return null;
    return _rawToDecimal(sell, BaseTokens.usdc.decimals);
  }

  static Decimal? _buyApproxUsd(TradeState state) {
    // USDC-sell path: `≈` USD value of the buy side equals the sell side
    // (minus fees, close enough for a display hint). We keep this simple —
    // the QuoteDetails card shows the real numbers.
    return _sellApproxUsd(state);
  }

  static String _toDecimal(BigInt raw, int decimals) {
    final d = _rawToDecimal(raw, decimals);
    final s = d.toString();
    final dot = s.indexOf('.');
    if (dot < 0) return s;
    return s.length - dot > 7 ? s.substring(0, dot + 7) : s;
  }

  static Decimal _rawToDecimal(BigInt raw, int decimals) {
    final base = BigInt.from(10).pow(decimals);
    return (Decimal.parse(raw.toString()) /
            Decimal.parse(base.toString()))
        .toDecimal(scaleOnInfinitePrecision: 18);
  }
}

class _FlipDivider extends StatelessWidget {
  const _FlipDivider({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Center(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.swap_vert_rounded,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _PriceHintTile extends StatelessWidget {
  const _PriceHintTile({required this.state});
  final TradeState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.bolt,
            size: 14,
            color: AppColors.accent,
          ),
          const SizedBox(width: 8),
          Text(
            state.loadingPrice ? l10n.loadingPrice : l10n.indicative,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.negative.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.negative.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            size: 16,
            color: AppColors.negative,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.negative,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuoteCountdown extends StatelessWidget {
  const _QuoteCountdown({required this.quote, required this.now});
  final SwapQuote quote;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final expires = quote.fetchedAt.add(quote.validFor);
    final remaining = expires.difference(now);
    final total = quote.validFor.inMilliseconds;
    final left = remaining.inMilliseconds.clamp(0, total);
    final fraction = total <= 0 ? 0.0 : left / total;
    final seconds = (remaining.inMilliseconds / 1000)
        .clamp(0.0, double.infinity)
        .ceil();
    final fresh = remaining > Duration.zero;
    final color =
        fresh ? AppColors.positive : AppColors.negative;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.timer_outlined, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              fresh
                  ? context.l10n.quoteFreshFor('$seconds')
                  : context.l10n.quoteExpired,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: fraction,
            backgroundColor: AppColors.border,
            color: color,
            minHeight: 3,
          ),
        ),
      ],
    );
  }
}
