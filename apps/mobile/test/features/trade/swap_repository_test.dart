import 'package:dex_app/core/web3/base_tokens.dart';
import 'package:dex_app/features/trade/swap_repository.dart';
import 'package:dex_app/features/trade/trade_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

void main() {
  late Dio dio;
  late DioAdapter adapter;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    adapter = DioAdapter(dio: dio);
  });

  group('ApiSwapRepository', () {
    test('getPrice parses normalized price JSON into BigInt fields', () async {
      adapter.onPost('/v1/swap/price', (server) {
        server.reply(200, {
          'sellAmount': '1000000',
          'buyAmount': '300000000000000',
          'minBuyAmount': '300000000000000',
          'networkFee': '10000000000000',
          'allowanceTarget': null,
          'transactionTo': null,
          'transactionData': null,
          'transactionValue': '0',
          'gas': '0',
          'gasPrice': '0',
          'routeLabels': <String>[],
          'fetchedAt': '2026-07-15T00:00:00.000Z',
          'validForSeconds': 10,
        });
      }, data: Matchers.any);

      final request = SwapRequest(
        sellToken: BaseTokens.usdc,
        buyToken: BaseTokens.eth,
        sellAmount: BigInt.from(1000000),
        taker: '0x1111111111111111111111111111111111111111',
        slippageBps: 50,
      );
      final price = await ApiSwapRepository(dio).getPrice(request);

      expect(price.sellAmount, BigInt.from(1000000));
      expect(price.buyAmount, BigInt.from(300000000000000));
      expect(price.networkFee, BigInt.from(10000000000000));
      expect(price.validFor, const Duration(seconds: 10));
      expect(price.fetchedAt, DateTime.utc(2026, 7, 15));
    });

    test('getQuote parses normalized quote JSON into BigInt fields', () async {
      adapter.onPost('/v1/swap/quote', (server) {
        server.reply(200, {
          'sellAmount': '1000000',
          'buyAmount': '300000000000000',
          'minBuyAmount': '298500000000000',
          'networkFee': '10000000000000',
          'allowanceTarget': '0x0000000000000000000000000000000000000001',
          'transactionTo': '0x0000000000000000000000000000000000000002',
          'transactionData': '0x1234',
          'transactionValue': '0',
          'gas': '220000',
          'gasPrice': '1000000',
          'routeLabels': <String>['Uniswap_V3'],
          'fetchedAt': '2026-07-15T00:00:00.000Z',
          'validForSeconds': 15,
        });
      }, data: Matchers.any);

      final request = SwapRequest(
        sellToken: BaseTokens.usdc,
        buyToken: BaseTokens.eth,
        sellAmount: BigInt.from(1000000),
        taker: '0x1111111111111111111111111111111111111111',
        slippageBps: 50,
      );
      final quote = await ApiSwapRepository(dio).getQuote(request);

      expect(quote.sellAmount, BigInt.from(1000000));
      expect(quote.buyAmount, BigInt.from(300000000000000));
      expect(quote.minBuyAmount, BigInt.from(298500000000000));
      expect(quote.networkFee, BigInt.from(10000000000000));
      expect(quote.allowanceTarget, '0x0000000000000000000000000000000000000001');
      expect(quote.transactionTo, '0x0000000000000000000000000000000000000002');
      expect(quote.transactionData, '0x1234');
      expect(quote.transactionValue, BigInt.zero);
      expect(quote.gas, BigInt.from(220000));
      expect(quote.gasPrice, BigInt.from(1000000));
      expect(quote.routeLabels, ['Uniswap_V3']);
      expect(quote.validFor, const Duration(seconds: 15));
      expect(quote.fetchedAt, DateTime.utc(2026, 7, 15));
      expect(quote.isFreshAt(DateTime.utc(2026, 7, 15)), isTrue);
    });
  });
}
