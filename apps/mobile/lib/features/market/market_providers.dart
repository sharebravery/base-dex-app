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

/// Raw asset list from `/v1/markets`. Kept separate from
/// [marketAssetsProvider] so a slow sparkline call never blocks the price
/// list from rendering.
final _assetsBaseProvider =
    FutureProvider<List<MarketAsset>>((ref) async {
  return ref.watch(marketRepositoryProvider).getAssets();
});

/// 7d sparklines keyed by asset id, from `/v1/sparklines`.
final sparklinesProvider =
    FutureProvider<Map<String, List<double>>>((ref) async {
  return ref.watch(marketRepositoryProvider).getSparklines();
});

/// Assets joined with their sparkline. If sparklines are still loading or
/// errored, the price list still renders — assets just come through with an
/// empty [MarketAsset.sparkline] and the tile falls back to a bare row.
final marketAssetsProvider =
    FutureProvider<List<MarketAsset>>((ref) async {
  final assets = await ref.watch(_assetsBaseProvider.future);
  final sparklinesAsync = ref.watch(sparklinesProvider);
  final sparklines = sparklinesAsync.when(
    data: (m) => m,
    loading: () => const <String, List<double>>{},
    error: (_, _) => const <String, List<double>>{},
  );
  return [
    for (final a in assets)
      a.copyWith(sparkline: sparklines[a.id] ?? const []),
  ];
});

/// Parameters for a candles query. Kept as a value type so Riverpod's
/// `.family` cache keys by (assetId, interval) — flipping the interval on the
/// pair-detail chart re-hits the cached Worker response instead of refetching.
final class CandlesQuery {
  const CandlesQuery({required this.assetId, required this.interval});
  final String assetId;
  final String interval;

  @override
  bool operator ==(Object other) =>
      other is CandlesQuery &&
      other.assetId == assetId &&
      other.interval == interval;
  @override
  int get hashCode => Object.hash(assetId, interval);
}

final candlesProvider =
    FutureProvider.family<List<Candle>, CandlesQuery>((ref, query) async {
  return ref
      .watch(marketRepositoryProvider)
      .getCandles(assetId: query.assetId, interval: query.interval);
});

/// Recent-trades tape for the pair-detail screen, keyed by asset id.
final recentTradesProvider =
    FutureProvider.family<List<RecentTrade>, String>((ref, assetId) async {
  return ref
      .watch(marketRepositoryProvider)
      .getRecentTrades(assetId: assetId, limit: 30);
});
