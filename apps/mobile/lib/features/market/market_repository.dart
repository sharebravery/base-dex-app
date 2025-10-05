import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:dex_app/core/web3/base_tokens.dart';
import 'package:dex_app/features/market/market_models.dart';

abstract interface class MarketRepository {
  Future<List<MarketAsset>> getAssets();
  Future<Map<String, List<double>>> getSparklines();
  Future<List<Candle>> getCandles({
    required String assetId,
    required String interval,
  });
  Future<List<RecentTrade>> getRecentTrades({
    required String assetId,
    int limit = 30,
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
      final highRaw = json['high24hUsd'] as String?;
      final lowRaw = json['low24hUsd'] as String?;
      return MarketAsset(
        id: json['id']! as String,
        baseSymbol: json['symbol']! as String,
        quoteSymbol: BaseTokens.usdc.symbol,
        name: json['name']! as String,
        priceUsd: Decimal.parse(json['priceUsd']! as String),
        change24hPercent:
            Decimal.parse(json['change24hPercent']! as String),
        volume24hUsd: Decimal.parse((json['volume24hUsd'] as String?) ?? '0'),
        high24hUsd: highRaw == null ? null : Decimal.parse(highRaw),
        low24hUsd: lowRaw == null ? null : Decimal.parse(lowRaw),
        tradable: json['tradable']! as bool,
        category:
            AssetCategory.fromString((json['category'] as String?) ?? 'layer1'),
      );
    }).toList(growable: false);
  }

  @override
  Future<Map<String, List<double>>> getSparklines() async {
    final response = await _dio.get<Map<String, Object?>>('/v1/sparklines');
    final raw = response.data!['sparklines']! as Map<String, Object?>;
    return raw.map((assetId, series) {
      final points = (series! as List<Object?>)
          .map((v) => double.parse(v! as String))
          .toList(growable: false);
      return MapEntry(assetId, points);
    });
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

  @override
  Future<List<RecentTrade>> getRecentTrades({
    required String assetId,
    int limit = 30,
  }) async {
    final response = await _dio.get<Map<String, Object?>>(
      '/v1/trades/recent',
      queryParameters: {'assetId': assetId, 'limit': limit},
    );
    final raw = response.data!['trades']! as List<Object?>;
    return raw.map((item) {
      final json = item! as Map<String, Object?>;
      return RecentTrade(
        id: json['id']! as int,
        price: Decimal.parse(json['price']! as String),
        qty: Decimal.parse(json['qty']! as String),
        quoteQty: Decimal.parse(json['quoteQty']! as String),
        timestamp: DateTime.parse(json['timestamp']! as String),
        isBuyerMaker: json['isBuyerMaker']! as bool,
      );
    }).toList(growable: false);
  }
}
