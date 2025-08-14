import 'package:dex_app/core/web3/erc20_abi.dart';
import 'package:http/http.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

/// Contract for reading EVM balances from Base mainnet.
///
/// Declared as an [abstract interface class] so tests can inject an in-memory
/// fake (see `FakeEvmRpc` in `portfolio_repository_test.dart`) and never open a
/// socket or touch the network under `flutter test` - mirroring the
/// [SecureStorage] seam from `core/secure_storage.dart`.
abstract interface class EvmRpc {
  Future<BigInt> nativeBalance(String address);
  Future<BigInt> erc20Balance(String token, String address);
  void dispose();
}

/// Production [EvmRpc] backed by [Web3Client] (web3dart).
final class Web3EvmRpc implements EvmRpc {
  Web3EvmRpc(Uri rpcUrl) : _client = Web3Client(rpcUrl.toString(), Client());
  final Web3Client _client;

  @override
  Future<BigInt> nativeBalance(String address) async {
    final amount = await _client.getBalance(EthereumAddress.fromHex(address));
    return amount.getInWei;
  }

  @override
  Future<BigInt> erc20Balance(String token, String address) async {
    final contract = DeployedContract(
      ContractAbi.fromJson(erc20BalanceAbi, 'ERC20'),
      EthereumAddress.fromHex(token),
    );
    final result = await _client.call(
      contract: contract,
      function: contract.function('balanceOf'),
      params: [EthereumAddress.fromHex(address)],
    );
    return result.single as BigInt;
  }

  @override
  void dispose() => _client.dispose();
}
