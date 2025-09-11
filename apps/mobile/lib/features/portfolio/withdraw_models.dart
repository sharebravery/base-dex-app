import 'package:dex_app/core/web3/base_tokens.dart';

/// Data classes for the Withdraw flow.
///
/// The controller itself is stateless — these classes describe the input the
/// UI collects and the parameters passed to the transaction service.
final class WithdrawRequest {
  const WithdrawRequest({
    required this.token,
    required this.destination,
    required this.rawAmount,
  });

  final TokenInfo token;
  final String destination;
  final BigInt rawAmount;
}
