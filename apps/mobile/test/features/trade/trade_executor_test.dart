import 'package:dex_app/core/security/biometric_gate.dart';
import 'package:dex_app/features/auth/auth_models.dart';
import 'package:dex_app/features/auth/wallet_service.dart';
import 'package:dex_app/features/trade/trade_executor.dart';
import 'package:dex_app/features/trade/trade_models.dart';
import 'package:dex_app/features/trade/transaction_service.dart';
import 'package:flutter_test/flutter_test.dart';

final class FakeBiometricGate implements BiometricGate {
  FakeBiometricGate(this.log, {this.result = true});
  final List<String> log;
  final bool result;

  @override
  Future<bool> authenticate(String reason) async {
    log.add('authenticate');
    return result;
  }
}

final class FakeWalletService implements WalletService {
  FakeWalletService(this.log);
  final List<String> log;

  @override
  Future<WalletSession?> restoreSession() async => null;
  @override
  Future<WalletSession> login(WalletLoginMethod method) => throw UnimplementedError();
  @override
  Future<String> signMessage(String message) => throw UnimplementedError();
  @override
  Future<void> logout() async {}

  @override
  Future<String> signTransaction(EvmTransactionRequest request) async {
    log.add(request.data.startsWith('0x095ea7b3') ? 'signApprove' : 'signSwap');
    return request.data;
  }
}

final class FakeChainGateway implements ChainGateway {
  FakeChainGateway(this.log, {required this.currentAllowance});
  final List<String> log;
  final BigInt currentAllowance;

  @override
  Future<BigInt> allowance(String owner, String token, String spender) async {
    log.add('readAllowance');
    return currentAllowance;
  }

  @override
  Future<int> nonce(String address) async => 1;

  @override
  Future<String> broadcast(String signedTransaction) async {
    final approval = signedTransaction.startsWith('0x095ea7b3');
    log.add(approval ? 'approve:1000000' : 'swap');
    return approval ? '0xapproval' : '0xswap';
  }

  @override
  Future<void> waitForSuccess(String txHash) async {
    log.add('waitApproval');
  }
}

SwapQuote quote(BigInt sellAmount) => SwapQuote(
      sellAmount: sellAmount,
      buyAmount: BigInt.from(300),
      minBuyAmount: BigInt.from(298),
      networkFee: BigInt.one,
      allowanceTarget: '0x0000000000000000000000000000000000000001',
      transactionTo: '0x0000000000000000000000000000000000000002',
      transactionData: '0x1234',
      transactionValue: BigInt.zero,
      gas: BigInt.from(220000),
      gasPrice: BigInt.one,
      routeLabels: const ['Uniswap_V3'],
      fetchedAt: DateTime.now(),
      validFor: const Duration(minutes: 1),
    );

TradeExecutor executor({
  required List<String> log,
  required BigInt allowance,
  bool authenticated = true,
}) {
  final chain = FakeChainGateway(log, currentAllowance: allowance);
  final service = TransactionService(
    wallet: FakeWalletService(log),
    chain: chain,
    allowedSpender: '0x0000000000000000000000000000000000000001',
    allowedSettler: '0x0000000000000000000000000000000000000002',
  );
  return TradeExecutor(
    biometric: FakeBiometricGate(log, result: authenticated),
    transactions: service,
    chain: chain,
    owner: '0x1111111111111111111111111111111111111111',
    sellToken: '0x833589fCD6eDb6E08f4c7C32D4f71b54bDa02913',
  );
}

void main() {
  test('insufficient USDC allowance approves exact amount before Swap', () async {
    final log = <String>[];
    await executor(log: log, allowance: BigInt.zero)
        .execute(quote(BigInt.from(1000000)));
    expect(log, [
      'authenticate',
      'readAllowance',
      'signApprove',
      'approve:1000000',
      'waitApproval',
      'signSwap',
      'swap',
    ]);
  });

  test('rejected device authentication performs no signing', () async {
    final log = <String>[];
    await expectLater(
      executor(log: log, allowance: BigInt.zero, authenticated: false)
          .execute(quote(BigInt.one)),
      throwsA(isA<TradeExecutionCancelled>()),
    );
    expect(log, ['authenticate']);
  });
}
