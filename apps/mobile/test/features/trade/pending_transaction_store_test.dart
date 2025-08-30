import 'package:dex_app/features/trade/pending_transaction.dart';
import 'package:dex_app/features/trade/pending_transaction_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('stores only non-sensitive pending metadata', () async {
    SharedPreferences.setMockInitialValues({});
    final store = PendingTransactionStore(SharedPreferencesAsync());
    final pending = PendingTransaction(
      txHash: '0xabc',
      walletAddress: '0x1111111111111111111111111111111111111111',
      operation: PendingOperation.swap,
      symbol: 'ETH/USDC',
      createdAt: DateTime.utc(2026),
    );
    await store.save(pending);
    expect(await store.loadAll(), [pending]);
  });
}
