import 'package:decimal/decimal.dart';
import 'package:dex_app/core/web3/base_chain.dart';
import 'package:dex_app/core/web3/evm_rpc.dart';
import 'package:dex_app/features/portfolio/portfolio_models.dart';

abstract interface class PortfolioRepository {
  Future<PortfolioSnapshot> load({
    required String address,
    required Decimal ethPriceUsd,
  });
}

final class RpcPortfolioRepository implements PortfolioRepository {
  RpcPortfolioRepository(this._rpc);
  final EvmRpc _rpc;

  @override
  Future<PortfolioSnapshot> load({required String address, required Decimal ethPriceUsd}) async {
    final results = await Future.wait([
      _rpc.nativeBalance(address),
      _rpc.erc20Balance(BaseChain.usdcAddress, address),
    ]);
    return PortfolioSnapshot.fromHoldings([
      Holding(symbol: 'ETH', rawBalance: results[0], decimals: 18, priceUsd: ethPriceUsd),
      Holding(symbol: 'USDC', rawBalance: results[1], decimals: 6, priceUsd: Decimal.one),
    ]);
  }
}
