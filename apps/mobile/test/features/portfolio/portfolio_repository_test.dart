import 'package:decimal/decimal.dart';
import 'package:dex_app/core/web3/evm_rpc.dart';
import 'package:dex_app/features/portfolio/portfolio_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory fake of [EvmRpc] so the repository test never opens a socket or
/// touches the network, mirroring the [FakeSecureStorage] pattern from
/// `app_session_repository_test.dart`.
final class FakeEvmRpc implements EvmRpc {
  FakeEvmRpc({required this.native, required this.erc20});

  final BigInt native;
  final BigInt erc20;

  @override
  Future<BigInt> nativeBalance(String address) async => native;

  @override
  Future<BigInt> erc20Balance(String token, String address) async => erc20;

  @override
  void dispose() {}
}

void main() {
  test('loads ETH and USDC holdings and sums exact decimal value', () async {
    final rpc = FakeEvmRpc(
      native: BigInt.parse('250000000000000000'), // 0.25 ETH
      erc20: BigInt.parse('500000000'), // 500 USDC
    );
    final repository = RpcPortfolioRepository(rpc);

    const address = '0x1111111111111111111111111111111111111111';
    final snapshot = await repository.load(
      address: address,
      ethPriceUsd: Decimal.parse('3200'),
    );

    expect(snapshot.holdings, hasLength(2));

    final eth = snapshot.holdings[0];
    expect(eth.symbol, 'ETH');
    expect(eth.decimals, 18);
    expect(eth.valueUsd.toString(), '800');

    final usdc = snapshot.holdings[1];
    expect(usdc.symbol, 'USDC');
    expect(usdc.decimals, 6);
    expect(usdc.valueUsd.toString(), '500');

    expect(snapshot.totalValueUsd.toString(), '1300');
  });
}
