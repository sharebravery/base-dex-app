import 'dart:async';
import 'package:dex_app/core/web3/base_tokens.dart';
import 'package:dex_app/features/trade/swap_repository.dart';
import 'package:dex_app/features/trade/trade_models.dart';
import 'package:flutter/foundation.dart';

final class TradeController extends ChangeNotifier {
  TradeController(this._repository);
  final SwapRepository _repository;
  TradeState state = const TradeState();
  Timer? _debounce;

  Future<void> updateAmount({
    required String amountText,
    required TokenInfo sellToken,
    required TokenInfo buyToken,
    required String taker,
  }) async {
    _debounce?.cancel();
    final amount = BigInt.tryParse(amountText);
    if (amount == null || amount <= BigInt.zero) {
      state = state.copyWith(
        amountText: amountText,
        request: null,
        price: null,
        quote: null,
        loadingPrice: false,
      );
      notifyListeners();
      return;
    }

    final request = SwapRequest(
      sellToken: sellToken,
      buyToken: buyToken,
      sellAmount: amount,
      taker: taker,
      slippageBps: state.slippageBps,
    );
    state = state.copyWith(
      amountText: amountText,
      request: request,
      loadingPrice: true,
      quote: null,
      errorCode: null,
    );
    notifyListeners();

    final completer = Completer<void>();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final price = await _repository.getPrice(request);
        if (state.request == request) {
          state = state.copyWith(price: price, loadingPrice: false);
          notifyListeners();
        }
      } catch (_) {
        state = state.copyWith(
          loadingPrice: false,
          errorCode: 'price_unavailable',
        );
        notifyListeners();
      } finally {
        completer.complete();
      }
    });
    await completer.future;
  }

  Future<void> review() async {
    final request = state.request;
    if (request == null) throw StateError('No valid request');
    state = state.copyWith(loadingQuote: true, errorCode: null);
    notifyListeners();
    try {
      final quote = await _repository.getQuote(request);
      state = state.copyWith(quote: quote, loadingQuote: false);
    } catch (_) {
      state = state.copyWith(
        loadingQuote: false,
        errorCode: 'quote_unavailable',
      );
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
