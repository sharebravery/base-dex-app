import 'package:dex_app/features/trade/pending_transaction.dart';
import 'package:dex_app/features/trade/pending_transaction_store.dart';
import 'package:dex_app/features/trade/transaction_tracker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class FakeReceiptSource implements ReceiptSource {
  FakeReceiptSource(this._states);
  final List<ReceiptState> _states;
  int _index = 0;

  @override
  Future<ReceiptState> receiptState(String txHash) async {
    final state = _index < _states.length
        ? _states[_index]
        : _states.last;
    _index++;
    return state;
  }
}

const _fastIntervals = [
  Duration(milliseconds: 1),
  Duration(milliseconds: 1),
  Duration(milliseconds: 1),
  Duration(milliseconds: 1),
  Duration(milliseconds: 1),
  Duration(milliseconds: 1),
];

PendingTransaction _pendingFixture({String txHash = '0xabc'}) {
  return PendingTransaction(
    txHash: txHash,
    walletAddress: '0x1111111111111111111111111111111111111111',
    operation: PendingOperation.swap,
    symbol: 'ETH/USDC',
    createdAt: DateTime.utc(2026),
  );
}

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('removes store entry after receipt confirms', () async {
    SharedPreferences.setMockInitialValues({});
    final store = PendingTransactionStore(SharedPreferencesAsync());
    final pending = _pendingFixture();
    await store.save(pending);

    final source = FakeReceiptSource([
      ReceiptState.pending,
      ReceiptState.confirmed,
    ]);
    final tracker = TransactionTracker(store, source, intervals: _fastIntervals);

    final result = await tracker.track(pending);

    expect(result, ReceiptState.confirmed);
    expect(await store.loadAll(), isEmpty);
  });

  test('removes store entry after receipt reverts', () async {
    SharedPreferences.setMockInitialValues({});
    final store = PendingTransactionStore(SharedPreferencesAsync());
    final pending = _pendingFixture();
    await store.save(pending);

    final source = FakeReceiptSource([
      ReceiptState.pending,
      ReceiptState.reverted,
    ]);
    final tracker = TransactionTracker(store, source, intervals: _fastIntervals);

    final result = await tracker.track(pending);

    expect(result, ReceiptState.reverted);
    expect(await store.loadAll(), isEmpty);
  });

  test('returns pending and keeps store entry when receipt never confirms', () async {
    SharedPreferences.setMockInitialValues({});
    final store = PendingTransactionStore(SharedPreferencesAsync());
    final pending = _pendingFixture();
    await store.save(pending);

    final source = FakeReceiptSource([ReceiptState.pending]);
    final tracker = TransactionTracker(store, source, intervals: _fastIntervals);

    final result = await tracker.track(pending);

    expect(result, ReceiptState.pending);
    expect(await store.loadAll(), [pending]);
  });
}
