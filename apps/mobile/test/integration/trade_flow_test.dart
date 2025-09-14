// End-to-end mocked trade flow test (Task 13 Modification 3).
//
// Runs entirely in-process using shared fakes — no device / emulator required.
// Drives the sequence:
//   updateAmount → getPrice
//   → review    → getQuote
//   → executor  → authenticate → readAllowance → signApprove → approve →
//                 waitApproval → signSwap → swap
//   → PendingTransactionStore save + TransactionTracker resolve
//   → PortfolioRepository reload with new balances.
import 'package:decimal/decimal.dart';
import 'package:dex_app/core/security/biometric_gate.dart';
import 'package:dex_app/core/web3/base_tokens.dart';
import 'package:dex_app/features/auth/auth_models.dart';
import 'package:dex_app/features/auth/wallet_service.dart';
import 'package:dex_app/features/portfolio/portfolio_models.dart';
import 'package:dex_app/features/portfolio/portfolio_repository.dart';
import 'package:dex_app/features/trade/pending_transaction.dart';
import 'package:dex_app/features/trade/pending_transaction_store.dart';
import 'package:dex_app/features/trade/swap_repository.dart';
import 'package:dex_app/features/trade/trade_controller.dart';
import 'package:dex_app/features/trade/trade_executor.dart';
import 'package:dex_app/features/trade/trade_models.dart';
import 'package:dex_app/features/trade/transaction_service.dart';
import 'package:dex_app/features/trade/transaction_tracker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

const _wallet = '0x1111111111111111111111111111111111111111';
const _spender = '0x0000000000000000000000000000000000000001';
const _settler = '0x0000000000000000000000000000000000000002';

final class FakeBiometricGate implements BiometricGate {
  FakeBiometricGate(this.log);
  final List<String> log;

  @override
  Future<bool> authenticate(String reason) async {
    log.add('authenticate');
    return true;
  }
}

final class FakeWalletService implements WalletService {
  FakeWalletService(this.log);
  final List<String> log;

  @override
  Future<WalletSession?> restoreSession() async =>
      const WalletSession(address: _wallet, email: null, displayName: null);
  @override
  Future<WalletSession> login(WalletLoginMethod method) => throw UnimplementedError();
  @override
  Future<String> signMessage(String message) async => '0xsig';
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
  Future<int> nonce(String address) async => 7;

  @override
  Future<String> broadcast(String signedTransaction) async {
    final approval = signedTransaction.startsWith('0x095ea7b3');
    log.add(approval ? 'approve:1000000' : 'swap');
    return approval ? '0xapprovalhash' : '0xswaphash';
  }

  @override
  Future<void> waitForSuccess(String txHash) async {
    log.add('waitApproval');
  }
}

final class FakeSwapRepository implements SwapRepository {
  int priceCalls = 0;
  int quoteCalls = 0;

  @override
  Future<SwapPrice> getPrice(SwapRequest request) async {
    priceCalls++;
    return SwapPrice(
      sellAmount: request.sellAmount,
      buyAmount: BigInt.from(300000000000000),
      networkFee: BigInt.one,
      fetchedAt: DateTime.now(),
      validFor: const Duration(seconds: 15),
    );
  }

  @override
  Future<SwapQuote> getQuote(SwapRequest request) async {
    quoteCalls++;
    return SwapQuote(
      sellAmount: request.sellAmount,
      buyAmount: BigInt.from(300000000000000),
      minBuyAmount: BigInt.from(298000000000000),
      networkFee: BigInt.one,
      allowanceTarget: _spender,
      transactionTo: _settler,
      transactionData: '0xabcdef',
      transactionValue: BigInt.zero,
      gas: BigInt.from(220000),
      gasPrice: BigInt.one,
      routeLabels: const ['Uniswap_V3'],
      fetchedAt: DateTime.now(),
      validFor: const Duration(minutes: 1),
    );
  }
}

final class FakeReceiptSource implements ReceiptSource {
  int _calls = 0;
  @override
  Future<ReceiptState> receiptState(String txHash) async {
    _calls++;
    return _calls < 2 ? ReceiptState.pending : ReceiptState.confirmed;
  }
}

final class FakePortfolioRepository implements PortfolioRepository {
  int calls = 0;
  @override
  Future<PortfolioSnapshot> load({
    required String address,
    required Decimal ethPriceUsd,
  }) async {
    calls++;
    // First call: pre-trade (USDC-heavy). Second call: post-trade (more ETH).
    if (calls == 1) {
      return PortfolioSnapshot.fromHoldings([
        Holding(
          symbol: 'ETH',
          rawBalance: BigInt.parse('100000000000000000'),
          decimals: 18,
          priceUsd: ethPriceUsd,
        ),
        Holding(
          symbol: 'USDC',
          rawBalance: BigInt.parse('1000000'),
          decimals: 6,
          priceUsd: Decimal.one,
        ),
      ]);
    }
    return PortfolioSnapshot.fromHoldings([
      Holding(
        symbol: 'ETH',
        rawBalance: BigInt.parse('400000000000000000'),
        decimals: 18,
        priceUsd: ethPriceUsd,
      ),
      Holding(
        symbol: 'USDC',
        rawBalance: BigInt.zero,
        decimals: 6,
        priceUsd: Decimal.one,
      ),
    ]);
  }
}

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    SharedPreferences.setMockInitialValues({});
  });

  test('mocked end-to-end trade flow drives full state machine', () async {
    final log = <String>[];
    final swapRepository = FakeSwapRepository();
    final chain = FakeChainGateway(log, currentAllowance: BigInt.zero);
    final wallet = FakeWalletService(log);
    final transactions = TransactionService(
      wallet: wallet,
      chain: chain,
      allowedSpender: _spender,
      allowedSettler: _settler,
    );
    final executor = TradeExecutor(
      biometric: FakeBiometricGate(log),
      transactions: transactions,
      chain: chain,
      owner: _wallet,
      sellToken: BaseTokens.usdc.address,
    );

    // 1) User edits amount -> Price request fires exactly once.
    final controller = TradeController(swapRepository);
    await controller.updateAmount(
      amountText: '1000000',
      sellToken: BaseTokens.usdc,
      buyToken: BaseTokens.eth,
      taker: _wallet,
    );
    expect(swapRepository.priceCalls, 1);
    expect(swapRepository.quoteCalls, 0);
    expect(controller.state.price, isNotNull);

    // 2) User taps Review -> Quote request fires exactly once.
    await controller.review();
    expect(swapRepository.quoteCalls, 1);
    final quote = controller.state.quote!;

    // 3) Executor drives the full authenticated approve+swap sequence.
    final result = await executor.execute(quote);
    expect(log, [
      'authenticate',
      'readAllowance',
      'signApprove',
      'approve:1000000',
      'waitApproval',
      'signSwap',
      'swap',
    ]);
    expect(result.approvalTxHash, '0xapprovalhash');
    expect(result.swapTxHash, '0xswaphash');

    // 4) The swap is registered as a PendingTransaction and the tracker
    //    resolves + removes it after the 2nd poll returns confirmed.
    final store = PendingTransactionStore(SharedPreferencesAsync());
    final pending = PendingTransaction(
      txHash: result.swapTxHash,
      walletAddress: _wallet,
      operation: PendingOperation.swap,
      symbol: 'USDC/ETH',
      createdAt: DateTime.utc(2026),
    );
    await store.save(pending);
    expect(await store.loadAll(), hasLength(1));

    final tracker = TransactionTracker(
      store,
      FakeReceiptSource(),
      intervals: const [Duration(milliseconds: 1), Duration(milliseconds: 1)],
    );
    final receipt = await tracker.track(pending);
    expect(receipt, ReceiptState.confirmed);
    expect(await store.loadAll(), isEmpty);

    // 5) Portfolio repository is reloaded with new balances after confirmation.
    final portfolio = FakePortfolioRepository();
    final before = await portfolio.load(address: _wallet, ethPriceUsd: Decimal.parse('3000'));
    final after = await portfolio.load(address: _wallet, ethPriceUsd: Decimal.parse('3000'));
    expect(portfolio.calls, 2);
    expect(after.totalValueUsd, isNot(before.totalValueUsd));
    expect(after.totalValueUsd > before.totalValueUsd, isTrue);
  });
}
