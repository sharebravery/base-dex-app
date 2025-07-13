import 'package:dex_app/features/market/market_models.dart';

final class MarketController {
  const MarketController();

  List<MarketAsset> loadFixtures() => List.unmodifiable(MarketAsset.fixtures);
}
