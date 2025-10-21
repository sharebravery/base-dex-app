import 'package:decimal/decimal.dart';
import 'package:dex_app/core/api_client.dart';
import 'package:dex_app/core/app_config.dart';
import 'package:dex_app/core/security/biometric_gate.dart';
import 'package:dex_app/core/web3/evm_rpc.dart';
import 'package:dex_app/features/auth/auth_models.dart';
import 'package:dex_app/features/auth/auth_providers.dart';
import 'package:dex_app/features/auth/wallet_service.dart';
import 'package:dex_app/features/portfolio/portfolio_providers.dart';
import 'package:dex_app/features/portfolio/portfolio_repository.dart';
import 'package:dex_app/features/settings/settings_models.dart';
import 'package:dex_app/features/settings/settings_providers.dart';
import 'package:dex_app/features/settings/settings_repository.dart';
import 'package:dex_app/features/trade/pending_transaction_store.dart';
import 'package:dex_app/features/trade/swap_repository.dart';
import 'package:dex_app/features/trade/trade_models.dart';
import 'package:dex_app/features/trade/trade_providers.dart';
import 'package:dex_app/features/trade/transaction_service.dart';
import 'package:dex_app/features/trade/transaction_tracker.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';

/// Public demo wallet address (Binance 8 hot wallet on Base — has visible
/// USDC + ETH balances). Read-only: nothing signs on-chain from this address.
const demoAddress = '0xf977814e90da44bfa03b6295a0616a897441acec';

const demoSession = WalletSession(
  address: demoAddress,
  email: 'demo@dex.app',
  displayName: 'Demo',
);

final class DemoWalletService implements WalletService {
  int _nonce = 1;

  @override
  Future<WalletSession?> restoreSession() async => demoSession;

  @override
  Future<WalletSession> login(WalletLoginMethod method) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return demoSession;
  }

  @override
  Future<String> signMessage(String message) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return '0xdemo_sig_${message.hashCode.toRadixString(16)}';
  }

  @override
  Future<String> signTransaction(EvmTransactionRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return '0xdemo_tx_${_nonce++}';
  }

  @override
  Future<void> logout() async {}
}

final class MockSwapRepository implements SwapRepository {
  MockSwapRepository(this._priceUsd);
  Decimal _priceUsd;

  set priceUsd(Decimal v) => _priceUsd = v;

  @override
  Future<SwapPrice> getPrice(SwapRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    // sellAmount is USDC base units (6 decimals). Convert to ETH base units
    // (18 decimals) at _priceUsd USD/ETH.
    final sellRaw = Decimal.parse(request.sellAmount.toString());
    final usdcAmount =
        (sellRaw / Decimal.parse('1000000')).toDecimal(scaleOnInfinitePrecision: 18);
    final ethAmount =
        (usdcAmount / _priceUsd).toDecimal(scaleOnInfinitePrecision: 18);
    final buyRaw =
        (ethAmount * Decimal.parse('1000000000000000000')).toBigInt();
    return SwapPrice(
      sellAmount: request.sellAmount,
      buyAmount: buyRaw,
      networkFee: BigInt.parse('1000000000000000'),
      fetchedAt: DateTime.now(),
      validFor: const Duration(seconds: 10),
    );
  }

  @override
  Future<SwapQuote> getQuote(SwapRequest request) async {
    final price = await getPrice(request);
    return SwapQuote(
      sellAmount: price.sellAmount,
      buyAmount: price.buyAmount,
      minBuyAmount: (price.buyAmount * BigInt.from(995)) ~/ BigInt.from(1000),
      networkFee: price.networkFee,
      allowanceTarget: '0x6131B5fae19EA4f9D964eAc0408E4408b66337b5',
      transactionTo: '0x6131B5fae19EA4f9D964eAc0408E4408b66337b5',
      // Demo aggregator never returns calldata — it's route-preview only.
      transactionData: null,
      transactionValue: BigInt.zero,
      gas: BigInt.from(220000),
      gasPrice: BigInt.from(1000000),
      routeLabels: const ['Uniswap_V3', 'Aerodrome'],
      fetchedAt: DateTime.now(),
      validFor: const Duration(seconds: 30),
    );
  }
}

final class DemoBiometricGate implements BiometricGate {
  @override
  Future<bool> authenticate(String reason) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return true;
  }
}

final class DemoChainGateway implements ChainGateway {
  int _nonce = 1;
  bool _approved = false;

  @override
  Future<BigInt> allowance(String owner, String token, String spender) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _approved ? BigInt.parse('1000000000000000000000000') : BigInt.zero;
  }

  @override
  Future<int> nonce(String address) async => _nonce++;

  @override
  Future<String> broadcast(String signedTransaction) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (signedTransaction.contains('demo_tx_1')) _approved = true;
    final id = DateTime.now().millisecondsSinceEpoch;
    return '0xdemo_broadcast_${id.toRadixString(16)}';
  }

  @override
  Future<void> waitForSuccess(String txHash) async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
  }
}

final class DemoReceiptSource implements ReceiptSource {
  final Map<String, int> _calls = {};

  @override
  Future<ReceiptState> receiptState(String txHash) async {
    final n = (_calls[txHash] ?? 0) + 1;
    _calls[txHash] = n;
    if (n >= 2) return ReceiptState.confirmed;
    return ReceiptState.pending;
  }
}

final class DemoSettingsRepository implements SettingsRepository {
  @override
  Future<AppSettings> update(AppSettings settings) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return settings;
  }
}

/// Provides all overrides needed for a fully-usable demo:
/// - REAL: market data (Binance via Worker), portfolio balances (Base RPC),
///   Swap price/quote (KyberSwap via Worker).
/// - MOCK: wallet signing, biometric, chain broadcast — Confirm never touches
///   the chain and the mobile client renders a "Demo — not broadcast" chip.
///
/// The `MockSwapRepository` remains available as a fallback / for tests but is
/// no longer wired at bootstrap: the app now shows real routes and quotes.
List<Override> buildMockOverrides(AppConfig config) {
  final prefs = SharedPreferencesAsync();
  final store = PendingTransactionStore(prefs);
  final rpc = Web3EvmRpc(config.baseRpcUrl);
  final apiDio = createApiClient(config.apiBaseUrl);
  final apiSwap = ApiSwapRepository(apiDio);

  return [
    walletServiceProvider.overrideWithValue(DemoWalletService()),
    portfolioRepositoryProvider.overrideWithValue(RpcPortfolioRepository(rpc)),
    ethPriceUsdProvider.overrideWithValue(Decimal.parse('3300')),
    swapRepositoryProvider.overrideWithValue(apiSwap),
    biometricGateProvider.overrideWithValue(DemoBiometricGate()),
    chainGatewayProvider.overrideWithValue(DemoChainGateway()),
    pendingTransactionStoreProvider.overrideWithValue(store),
    receiptSourceProvider.overrideWithValue(DemoReceiptSource()),
    settingsRepositoryProvider.overrideWithValue(DemoSettingsRepository()),
  ];
}
