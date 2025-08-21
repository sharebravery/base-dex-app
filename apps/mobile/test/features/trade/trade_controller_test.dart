import 'package:dex_app/core/web3/base_tokens.dart';
import 'package:dex_app/features/trade/trade_controller.dart';
import 'package:dex_app/features/trade/trade_models.dart';
import 'package:dex_app/features/trade/swap_repository.dart';
import 'package:flutter_test/flutter_test.dart';

final class FakeSwapRepository implements SwapRepository {
  int priceCalls = 0;
  int quoteCalls = 0;

  @override
  Future<SwapPrice> getPrice(SwapRequest request) async {
    priceCalls++;
    return SwapPrice(
      sellAmount: request.sellAmount,
      buyAmount: BigInt.from(300),
      networkFee: BigInt.one,
      fetchedAt: DateTime.utc(2026),
      validFor: const Duration(seconds: 10),
    );
  }

  @override
  Future<SwapQuote> getQuote(SwapRequest request) async {
    quoteCalls++;
    return SwapQuote(
      sellAmount: request.sellAmount,
      buyAmount: BigInt.from(300),
      minBuyAmount: BigInt.from(298),
      networkFee: BigInt.one,
      allowanceTarget: '0x0000000000000000000000000000000000000001',
      transactionTo: '0x0000000000000000000000000000000000000002',
      transactionData: '0x1234',
      transactionValue: BigInt.zero,
      gas: BigInt.from(220000),
      gasPrice: BigInt.one,
      routeLabels: const ['Uniswap_V3'],
      fetchedAt: DateTime.utc(2026),
      validFor: const Duration(seconds: 15),
    );
  }
}

void main() {
  test('editing requests Price and Review requests Quote', () async {
    final repository = FakeSwapRepository();
    final controller = TradeController(repository);
    await controller.updateAmount(
      amountText: '1',
      sellToken: BaseTokens.usdc,
      buyToken: BaseTokens.eth,
      taker: '0x1111111111111111111111111111111111111111',
    );
    expect(repository.priceCalls, 1);
    expect(repository.quoteCalls, 0);
    await controller.review();
    expect(repository.quoteCalls, 1);
  });
}
