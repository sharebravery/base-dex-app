import 'package:decimal/decimal.dart';

/// Single trade in the recent-trades tape on the pair detail screen.
///
/// `isBuyerMaker` mirrors Binance semantics: true means the aggressive side
/// was a seller (red row), false means the aggressive side was a buyer
/// (green row).
final class RecentTrade {
  const RecentTrade({
    required this.id,
    required this.price,
    required this.qty,
    required this.quoteQty,
    required this.timestamp,
    required this.isBuyerMaker,
  });

  final int id;
  final Decimal price;
  final Decimal qty;
  final Decimal quoteQty;
  final DateTime timestamp;
  final bool isBuyerMaker;
}

final class Candle {
  const Candle({
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });

  final DateTime timestamp;
  final Decimal open;
  final Decimal high;
  final Decimal low;
  final Decimal close;
}

/// Coarse buckets for the market screen filter chips. Values are the strings
/// the Worker emits — keep them stable and unlocalized; the UI localizes the
/// labels separately.
enum AssetCategory {
  layer1,
  layer2,
  defi,
  meme,
  stable;

  static AssetCategory fromString(String raw) {
    return switch (raw) {
      'layer1' => AssetCategory.layer1,
      'layer2' => AssetCategory.layer2,
      'defi' => AssetCategory.defi,
      'meme' => AssetCategory.meme,
      'stable' => AssetCategory.stable,
      _ => AssetCategory.layer1,
    };
  }
}

final class MarketAsset {
  const MarketAsset({
    required this.id,
    required this.baseSymbol,
    required this.quoteSymbol,
    required this.name,
    required this.priceUsd,
    required this.change24hPercent,
    required this.volume24hUsd,
    required this.tradable,
    required this.category,
    this.high24hUsd,
    this.low24hUsd,
    this.sparkline = const [],
  });

  final String id;
  final String baseSymbol;
  final String quoteSymbol;
  final String name;
  final Decimal priceUsd;
  final Decimal change24hPercent;

  /// 24h quote volume in USD. `Decimal.zero` for the stable placeholder (USDC).
  final Decimal volume24hUsd;

  /// 24h high/low in USD. Null for the stable placeholder (USDC) where a range
  /// is meaningless.
  final Decimal? high24hUsd;
  final Decimal? low24hUsd;

  final bool tradable;

  final AssetCategory category;

  /// 7-day close prices (typically 42 × 4h). Empty for stables/on-error;
  /// widgets should treat empty as "no chart" rather than showing a flat line.
  final List<double> sparkline;

  MarketAsset copyWith({List<double>? sparkline}) => MarketAsset(
        id: id,
        baseSymbol: baseSymbol,
        quoteSymbol: quoteSymbol,
        name: name,
        priceUsd: priceUsd,
        change24hPercent: change24hPercent,
        volume24hUsd: volume24hUsd,
        high24hUsd: high24hUsd,
        low24hUsd: low24hUsd,
        tradable: tradable,
        category: category,
        sparkline: sparkline ?? this.sparkline,
      );

  static final fixtures = [
    MarketAsset(
      id: 'ethereum',
      baseSymbol: 'ETH',
      quoteSymbol: 'USDC',
      name: 'Ethereum',
      priceUsd: Decimal.parse('3240.12'),
      change24hPercent: Decimal.parse('2.41'),
      volume24hUsd: Decimal.parse('812000000'),
      high24hUsd: Decimal.parse('3290.10'),
      low24hUsd: Decimal.parse('3180.42'),
      tradable: true,
      category: AssetCategory.layer1,
    ),
    MarketAsset(
      id: 'bitcoin',
      baseSymbol: 'BTC',
      quoteSymbol: 'USDC',
      name: 'Bitcoin',
      priceUsd: Decimal.parse('97500.00'),
      change24hPercent: Decimal.parse('-0.82'),
      volume24hUsd: Decimal.parse('3200000000'),
      high24hUsd: Decimal.parse('98420.00'),
      low24hUsd: Decimal.parse('96780.00'),
      tradable: false,
      category: AssetCategory.layer1,
    ),
    MarketAsset(
      id: 'solana',
      baseSymbol: 'SOL',
      quoteSymbol: 'USDC',
      name: 'Solana',
      priceUsd: Decimal.parse('188.40'),
      change24hPercent: Decimal.parse('1.12'),
      volume24hUsd: Decimal.parse('410000000'),
      high24hUsd: Decimal.parse('192.50'),
      low24hUsd: Decimal.parse('184.20'),
      tradable: false,
      category: AssetCategory.layer1,
    ),
  ];
}
