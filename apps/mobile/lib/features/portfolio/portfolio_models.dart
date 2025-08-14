import 'package:decimal/decimal.dart';

final class Holding {
  const Holding({
    required this.symbol,
    required this.rawBalance,
    required this.decimals,
    required this.priceUsd,
  });

  final String symbol;
  final BigInt rawBalance;
  final int decimals;
  final Decimal priceUsd;

  Decimal get amount =>
      (Decimal.parse(rawBalance.toString()) / Decimal.fromInt(BigInt.from(10).pow(decimals).toInt())).toDecimal();
  Decimal get valueUsd => amount * priceUsd;
}

final class PortfolioSnapshot {
  const PortfolioSnapshot({required this.holdings, required this.totalValueUsd});

  factory PortfolioSnapshot.fromHoldings(List<Holding> holdings) {
    final total = holdings.fold(Decimal.zero, (sum, item) => sum + item.valueUsd);
    return PortfolioSnapshot(holdings: List.unmodifiable(holdings), totalValueUsd: total);
  }

  final List<Holding> holdings;
  final Decimal totalValueUsd;
}
