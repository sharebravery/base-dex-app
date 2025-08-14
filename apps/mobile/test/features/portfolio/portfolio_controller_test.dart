import 'package:decimal/decimal.dart';
import 'package:dex_app/features/portfolio/portfolio_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calculates total value from exact decimal holdings', () {
    final snapshot = PortfolioSnapshot.fromHoldings([
      Holding(symbol: 'ETH', rawBalance: BigInt.parse('250000000000000000'), decimals: 18, priceUsd: Decimal.parse('3200')),
      Holding(symbol: 'USDC', rawBalance: BigInt.parse('500000000'), decimals: 6, priceUsd: Decimal.one),
    ]);
    expect(snapshot.totalValueUsd.toString(), '1300');
  });
}
