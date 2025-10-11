import 'package:decimal/decimal.dart';
import 'package:dex_app/core/web3/base_tokens.dart';
import 'package:dex_app/l10n/l10n_extension.dart';
import 'package:dex_app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// One side of the swap form — a big card with the amount input on the left
/// and a Token chip on the right. Two variants:
///
/// - `SwapAmountField.pay(...)` — editable amount, "You pay" label, optional
///   `onMax` for the balance chip.
/// - `SwapAmountField.receive(...)` — read-only amount, "You receive"
///   label. Loading state renders shimmer text.
class SwapAmountField extends StatelessWidget {
  const SwapAmountField._({
    required this.token,
    required this.value,
    required this.isEditable,
    required this.controller,
    required this.onChanged,
    required this.approxUsd,
    required this.balance,
    required this.onMax,
    required this.label,
    required this.loading,
  });

  /// Editable pay-side card.
  factory SwapAmountField.pay({
    Key? key,
    required TokenInfo token,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    required BuildContext context,
    Decimal? approxUsd,
    Decimal? balance,
    VoidCallback? onMax,
  }) {
    return SwapAmountField._(
      token: token,
      value: null,
      isEditable: true,
      controller: controller,
      onChanged: onChanged,
      approxUsd: approxUsd,
      balance: balance,
      onMax: onMax,
      label: context.l10n.youPay,
      loading: false,
    );
  }

  /// Read-only receive-side card.
  factory SwapAmountField.receive({
    Key? key,
    required TokenInfo token,
    required String value,
    required BuildContext context,
    Decimal? approxUsd,
    Decimal? balance,
    bool loading = false,
  }) {
    return SwapAmountField._(
      token: token,
      value: value,
      isEditable: false,
      controller: null,
      onChanged: null,
      approxUsd: approxUsd,
      balance: balance,
      onMax: null,
      label: context.l10n.youReceive,
      loading: loading,
    );
  }

  final TokenInfo token;
  final String? value;
  final bool isEditable;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final Decimal? approxUsd;
  final Decimal? balance;
  final VoidCallback? onMax;
  final String label;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const Spacer(),
              if (balance != null)
                Text(
                  '${context.l10n.balance}: ${_formatBalance(balance!)}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textMuted,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                ),
              if (onMax != null) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: onMax,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    child: Text(
                      context.l10n.max,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _buildAmount(context)),
              _TokenChip(token: token),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            approxUsd == null
                ? ' '
                : '≈ \$${_formatUsd(approxUsd!)}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmount(BuildContext context) {
    if (isEditable) {
      return TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          // Digits only for now — the controller stringifies to a BigInt in
          // sell-token base units. Decimal handling would need to convert.
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: const InputDecoration(
          hintText: '0',
          isCollapsed: true,
          isDense: true,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
      );
    }
    if (loading) {
      return _ShimmerText(
        text: '0.0',
        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
      );
    }
    return Text(
      value ?? '0',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
    );
  }

  static String _formatUsd(Decimal v) {
    final d = v.toDouble();
    if (d >= 1000) return d.toStringAsFixed(2);
    if (d >= 1) return d.toStringAsFixed(2);
    if (d >= 0.01) return d.toStringAsFixed(4);
    return d.toStringAsExponential(2);
  }

  static String _formatBalance(Decimal v) {
    final s = v.toString();
    final dot = s.indexOf('.');
    if (dot >= 0 && s.length - dot - 1 > 4) return s.substring(0, dot + 5);
    return s;
  }
}

class _TokenChip extends StatelessWidget {
  const _TokenChip({required this.token});
  final TokenInfo token;

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(token.symbol);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: palette,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              token.symbol.characters.first,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            token.symbol,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }

  static List<Color> _paletteFor(String symbol) {
    switch (symbol.toUpperCase()) {
      case 'ETH':
        return const [Color(0xFF627EEA), Color(0xFF00E5FF)];
      case 'USDC':
        return const [Color(0xFF2775CA), Color(0xFF00E5FF)];
    }
    return const [AppColors.gradientStart, AppColors.gradientEnd];
  }
}

class _ShimmerText extends StatelessWidget {
  const _ShimmerText({required this.text, this.style});
  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: style);
  }
}
