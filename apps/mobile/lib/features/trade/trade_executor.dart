import 'package:dex_app/core/security/biometric_gate.dart';
import 'package:dex_app/features/trade/trade_models.dart';
import 'package:dex_app/features/trade/transaction_service.dart';

class TradeExecutionCancelled implements Exception {}

enum TransactionStage {
  preparing,
  authenticating,
  approving,
  approvalSubmitted,
  swapping,
  submitted,
  confirmed,
  failed,
}

final class TradeExecutionResult {
  const TradeExecutionResult({this.approvalTxHash, required this.swapTxHash});
  final String? approvalTxHash;
  final String swapTxHash;
}

final class TradeExecutor {
  TradeExecutor({
    required this.biometric,
    required this.transactions,
    required this.chain,
    required this.owner,
    required this.sellToken,
  });

  final BiometricGate biometric;
  final TransactionService transactions;
  final ChainGateway chain;
  final String owner;
  final String sellToken;

  Future<TradeExecutionResult> execute(SwapQuote quote) async {
    if (!quote.isFreshAt(DateTime.now())) throw StateError('Quote expired');
    if (!await biometric.authenticate('Confirm on-chain transaction')) {
      throw TradeExecutionCancelled();
    }

    String? approvalHash;
    final spender = quote.allowanceTarget;
    if (spender != null) {
      final current = await chain.allowance(owner, sellToken, spender);
      if (current < quote.sellAmount) {
        approvalHash = await transactions.approveExact(
          owner: owner,
          token: sellToken,
          spender: spender,
          amount: quote.sellAmount,
        );
        await chain.waitForSuccess(approvalHash);
      }
    }

    final swapHash = await transactions.swap(owner: owner, quote: quote);
    return TradeExecutionResult(approvalTxHash: approvalHash, swapTxHash: swapHash);
  }
}
