import 'package:dex_app/features/auth/auth_models.dart';
import 'package:dex_app/features/auth/wallet_service.dart';
import 'package:dex_app/features/trade/trade_models.dart';

abstract interface class ChainGateway {
  Future<BigInt> allowance(String owner, String token, String spender);
  Future<int> nonce(String address);
  Future<String> broadcast(String signedTransaction);
  Future<void> waitForSuccess(String txHash);
}

final class TransactionService {
  TransactionService({
    required this.wallet,
    required this.chain,
    required this.allowedSpender,
    required this.allowedSettler,
  });

  final WalletService wallet;
  final ChainGateway chain;
  final String allowedSpender;
  final String allowedSettler;

  Future<String> approveExact({
    required String owner,
    required String token,
    required String spender,
    required BigInt amount,
  }) async {
    if (spender.toLowerCase() != allowedSpender.toLowerCase()) {
      throw StateError('Unexpected approval spender');
    }
    final request = EvmTransactionRequest(
      to: token,
      data: encodeApprove(spender, amount),
      value: BigInt.zero,
      // TODO(phase-4): replace placeholder gas params with a FeeEstimator/GasOracle
      // query before mainnet wiring. Current values (100k gas, 1 wei fees) will
      // strand approve transactions on real Base.
      gasLimit: BigInt.from(100000),
      maxFeePerGas: BigInt.from(1),
      maxPriorityFeePerGas: BigInt.from(1),
      nonce: await chain.nonce(owner),
      chainId: 8453,
    );
    return chain.broadcast(await wallet.signTransaction(request));
  }

  Future<String> sendNative({
    required String owner,
    required String to,
    required BigInt amount,
  }) async {
    final request = EvmTransactionRequest(
      to: to,
      data: '0x',
      value: amount,
      // TODO(phase-4-bootstrap): placeholder gas params - replace with
      // FeeEstimator before mainnet wiring.
      gasLimit: BigInt.from(21000),
      maxFeePerGas: BigInt.from(1),
      maxPriorityFeePerGas: BigInt.from(1),
      nonce: await chain.nonce(owner),
      chainId: 8453,
    );
    return chain.broadcast(await wallet.signTransaction(request));
  }

  Future<String> sendErc20Transfer({
    required String owner,
    required String token,
    required String to,
    required BigInt amount,
  }) async {
    final request = EvmTransactionRequest(
      to: token,
      data: encodeErc20Transfer(to, amount),
      value: BigInt.zero,
      // TODO(phase-4-bootstrap): placeholder gas params - replace with
      // FeeEstimator before mainnet wiring.
      gasLimit: BigInt.from(65000),
      maxFeePerGas: BigInt.from(1),
      maxPriorityFeePerGas: BigInt.from(1),
      nonce: await chain.nonce(owner),
      chainId: 8453,
    );
    return chain.broadcast(await wallet.signTransaction(request));
  }

  Future<String> swap({required String owner, required SwapQuote quote}) async {
    if (quote.transactionTo.toLowerCase() != allowedSettler.toLowerCase()) {
      throw StateError('Unexpected Swap destination');
    }
    final request = EvmTransactionRequest(
      to: quote.transactionTo,
      data: quote.transactionData,
      value: quote.transactionValue,
      gasLimit: quote.gas,
      // TODO(phase-4): quote.gasPrice is 0x's legacy gasPrice hint; using it as
      // EIP-1559 maxFeePerGas with zero priority underprices on a rising basefee.
      // Add a safety multiplier and non-zero priority fee before mainnet wiring.
      maxFeePerGas: quote.gasPrice,
      maxPriorityFeePerGas: BigInt.zero,
      nonce: await chain.nonce(owner),
      chainId: 8453,
    );
    return chain.broadcast(await wallet.signTransaction(request));
  }
}

String encodeApprove(String spender, BigInt amount) {
  final selector = '095ea7b3';
  final address = spender.toLowerCase().replaceFirst('0x', '').padLeft(64, '0');
  final value = amount.toRadixString(16).padLeft(64, '0');
  return '0x$selector$address$value';
}

String encodeErc20Transfer(String to, BigInt amount) {
  const selector = 'a9059cbb';
  final address = to.toLowerCase().replaceFirst('0x', '').padLeft(64, '0');
  final value = amount.toRadixString(16).padLeft(64, '0');
  return '0x$selector$address$value';
}
