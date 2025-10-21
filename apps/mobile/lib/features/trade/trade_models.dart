import 'package:dex_app/core/web3/base_tokens.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
part 'trade_models.freezed.dart';

final class SwapRequest {
  const SwapRequest({
    required this.sellToken,
    required this.buyToken,
    required this.sellAmount,
    required this.taker,
    required this.slippageBps,
  });
  final TokenInfo sellToken;
  final TokenInfo buyToken;
  final BigInt sellAmount;
  final String taker;
  final int slippageBps;
}

@freezed
abstract class SwapPrice with _$SwapPrice {
  const factory SwapPrice({
    required BigInt sellAmount,
    required BigInt buyAmount,
    required BigInt networkFee,
    required DateTime fetchedAt,
    required Duration validFor,
  }) = _SwapPrice;
}

@freezed
abstract class SwapQuote with _$SwapQuote {
  const SwapQuote._();
  const factory SwapQuote({
    required BigInt sellAmount,
    required BigInt buyAmount,
    required BigInt minBuyAmount,
    required BigInt networkFee,
    required String? allowanceTarget,
    required String transactionTo,
    // Null when the aggregator only returns a route preview (KyberSwap
    // `/routes` without follow-up `/route/build`). In demo mode we never sign
    // on-chain, so the mobile client leaves this null and renders a
    // "Demo — not broadcast" chip on the confirmation sheet.
    required String? transactionData,
    required BigInt transactionValue,
    required BigInt gas,
    required BigInt gasPrice,
    required List<String> routeLabels,
    required DateTime fetchedAt,
    required Duration validFor,
  }) = _SwapQuote;

  bool isFreshAt(DateTime now) => now.isBefore(fetchedAt.add(validFor));
}

@freezed
abstract class TradeState with _$TradeState {
  const factory TradeState({
    @Default('') String amountText,
    @Default(50) int slippageBps,
    SwapRequest? request,
    SwapPrice? price,
    SwapQuote? quote,
    @Default(false) bool loadingPrice,
    @Default(false) bool loadingQuote,
    String? errorCode,
  }) = _TradeState;
}
