import 'package:dex_app/core/security/biometric_gate.dart';
import 'package:dex_app/core/web3/base_tokens.dart';
import 'package:dex_app/features/auth/auth_providers.dart';
import 'package:dex_app/features/trade/pending_transaction_store.dart';
import 'package:dex_app/features/trade/swap_repository.dart';
import 'package:dex_app/features/trade/trade_controller.dart';
import 'package:dex_app/features/trade/trade_executor.dart';
import 'package:dex_app/features/trade/transaction_service.dart';
import 'package:dex_app/features/trade/transaction_tracker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final swapRepositoryProvider = Provider<SwapRepository>((ref) {
  throw StateError('swapRepositoryProvider must be overridden at bootstrap');
});

final tradeControllerProvider = Provider.autoDispose<TradeController>((ref) {
  final controller = TradeController(ref.watch(swapRepositoryProvider));
  ref.onDispose(controller.dispose);
  return controller;
});

final biometricGateProvider = Provider<BiometricGate>((ref) {
  throw StateError('biometricGateProvider must be overridden at bootstrap');
});

final chainGatewayProvider = Provider<ChainGateway>((ref) {
  throw StateError('chainGatewayProvider must be overridden at bootstrap');
});

final pendingTransactionStoreProvider =
    Provider<PendingTransactionStore>((ref) {
  throw StateError(
    'pendingTransactionStoreProvider must be overridden at bootstrap',
  );
});

final receiptSourceProvider = Provider<ReceiptSource>((ref) {
  throw StateError('receiptSourceProvider must be overridden at bootstrap');
});

final transactionTrackerProvider = Provider<TransactionTracker>((ref) {
  return TransactionTracker(
    ref.watch(pendingTransactionStoreProvider),
    ref.watch(receiptSourceProvider),
  );
});

/// KyberSwap Base router — the allowance target for USDC sells AND the
/// destination for the swap tx. In demo mode we never actually broadcast, but
/// TransactionService still gates on these constants; keep them aligned with
/// what the Worker returns so the mock code path stays consistent.
const kyberSwapRouterBase = '0x6131B5fae19EA4f9D964eAc0408E4408b66337b5';

final transactionServiceProvider = Provider<TransactionService>((ref) {
  return TransactionService(
    wallet: ref.watch(walletServiceProvider),
    chain: ref.watch(chainGatewayProvider),
    allowedSpender: kyberSwapRouterBase,
    allowedSettler: kyberSwapRouterBase,
  );
});

final tradeExecutorProvider = Provider<TradeExecutor>((ref) {
  final session = ref.watch(activeWalletSessionProvider);
  return TradeExecutor(
    biometric: ref.watch(biometricGateProvider),
    transactions: ref.watch(transactionServiceProvider),
    chain: ref.watch(chainGatewayProvider),
    owner: session?.address ?? '0x0000000000000000000000000000000000000000',
    sellToken: BaseTokens.usdc.address,
  );
});
