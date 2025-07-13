import 'package:decimal/decimal.dart';

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

final class MarketAsset {
  const MarketAsset({
    required this.id,
    required this.baseSymbol,
    required this.quoteSymbol,
    required this.name,
    required this.priceUsd,
    required this.change24hPercent,
    required this.tradable,
  });

  final String id;
  final String baseSymbol;
  final String quoteSymbol;
  final String name;
  final Decimal priceUsd;
  final Decimal change24hPercent;
  final bool tradable;

  static final fixtures = [
    MarketAsset(
      id: 'ethereum',
      baseSymbol: 'ETH',
      quoteSymbol: 'USDC',
      name: 'Ethereum',
      priceUsd: Decimal.parse('3240.12'),
      change24hPercent: Decimal.parse('2.41'),
      tradable: true,
    ),
    MarketAsset(
      id: 'bitcoin',
      baseSymbol: 'BTC',
      quoteSymbol: 'USDC',
      name: 'Bitcoin',
      priceUsd: Decimal.parse('97500.00'),
      change24hPercent: Decimal.parse('-0.82'),
      tradable: false,
    ),
    MarketAsset(
      id: 'solana',
      baseSymbol: 'SOL',
      quoteSymbol: 'USDC',
      name: 'Solana',
      priceUsd: Decimal.parse('188.40'),
      change24hPercent: Decimal.parse('1.12'),
      tradable: false,
    ),
  ];
}
