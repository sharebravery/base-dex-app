enum WalletLoginMethod { email, apple, google }

final class WalletSession {
  const WalletSession({
    required this.address,
    required this.email,
    required this.displayName,
  });

  final String address;
  final String? email;
  final String? displayName;
}

final class EvmTransactionRequest {
  const EvmTransactionRequest({
    required this.to,
    required this.data,
    required this.value,
    required this.gasLimit,
    required this.maxFeePerGas,
    required this.maxPriorityFeePerGas,
    required this.nonce,
    required this.chainId,
  });

  final String to;
  final String data;
  final BigInt value;
  final BigInt gasLimit;
  final BigInt maxFeePerGas;
  final BigInt maxPriorityFeePerGas;
  final int nonce;
  final int chainId;
}
