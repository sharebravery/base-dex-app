import 'package:dex_app/features/market/market_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

void main() {
  test('parses decimal strings without double authority', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    final adapter = DioAdapter(dio: dio);
    adapter.onGet('/v1/markets', (server) {
      server.reply(200, {
        'assets': [
          {
            'id': 'ethereum',
            'symbol': 'ETH',
            'name': 'Ethereum',
            'priceUsd': '3240.12',
            'change24hPercent': '2.41',
            'volume24hUsd': '812000000',
            'tradable': true,
          }
        ]
      });
    });

    final assets = await ApiMarketRepository(dio).getAssets();
    expect(assets.single.priceUsd.toString(), '3240.12');
    expect(assets.single.tradable, isTrue);
  });
}
