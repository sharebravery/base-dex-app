import 'package:dex_app/core/api_client.dart';
import 'package:dex_app/core/app_config.dart';
import 'package:dex_app/features/market/market_models.dart';
import 'package:dex_app/features/market/market_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _dioProvider = Provider<Dio>((ref) {
  return createApiClient(AppConfig.fromEnvironment().apiBaseUrl);
});

final marketRepositoryProvider = Provider<MarketRepository>((ref) {
  return ApiMarketRepository(ref.watch(_dioProvider));
});

final marketAssetsProvider = FutureProvider<List<MarketAsset>>((ref) async {
  return ref.watch(marketRepositoryProvider).getAssets();
});
