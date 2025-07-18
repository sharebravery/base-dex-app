import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:dex_app/core/web3/base_tokens.dart';
import 'package:dex_app/features/market/market_models.dart';

abstract interface class MarketRepository {
  Future<List<MarketAsset>> getAssets();
  Future<List<Candle>> getCandles({
    required String assetId,
    required String interval,
  });
}

final class ApiMarketRepository implements MarketRepository {
  ApiMarketRepository(this._dio);
  final Dio _dio;

  @override
  Future<List<MarketAsset>> getAssets() async {
    final response = await _dio.get<Map<String, Object?>>('/v1/markets');
    final rawAssets = response.data!['assets']! as List<Object?>;
    return rawAssets.map((raw) {
      final json = raw! as Map<String, Object?>;
      return MarketAsset(
        id: json['id']! as String,
        baseSymbol: json['symbol']! as String,
        quoteSymbol: BaseTokens.usdc.symbol,
        name: json['name']! as String,
        priceUsd: Decimal.parse(json['priceUsd']! as String),
        change24hPercent:
            Decimal.parse(json['change24hPercent']! as String),
        tradable: json['tradable']! as bool,
      );
    }).toList(growable: false);
  }

  @override
  Future<List<Candle>> getCandles({
    required String assetId,
    required String interval,
  }) async {
    final response = await _dio.get<Map<String, Object?>>(
      '/v1/candles',
      queryParameters: {'assetId': assetId, 'interval': interval},
    );
    final raw = response.data!['candles']! as List<Object?>;
    return raw.map((item) {
      final json = item! as Map<String, Object?>;
      return Candle(
        timestamp: DateTime.parse(json['timestamp']! as String),
        open: Decimal.parse(json['open']! as String),
        high: Decimal.parse(json['high']! as String),
        low: Decimal.parse(json['low']! as String),
        close: Decimal.parse(json['close']! as String),
      );
    }).toList(growable: false);
  }
}
