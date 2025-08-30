import 'dart:async';
import 'package:dex_app/features/trade/pending_transaction.dart';
import 'package:dex_app/features/trade/pending_transaction_store.dart';

enum ReceiptState { pending, confirmed, reverted }

abstract interface class ReceiptSource {
  Future<ReceiptState> receiptState(String txHash);
}

const defaultTrackerIntervals = [
  Duration(seconds: 2),
  Duration(seconds: 3),
  Duration(seconds: 5),
  Duration(seconds: 8),
  Duration(seconds: 13),
  Duration(seconds: 20),
];

final class TransactionTracker {
  TransactionTracker(
    this._store,
    this._source, {
    this.intervals = defaultTrackerIntervals,
  });
  final PendingTransactionStore _store;
  final ReceiptSource _source;
  final List<Duration> intervals;

  Future<ReceiptState> track(PendingTransaction transaction) async {
    for (final interval in intervals) {
      final state = await _source.receiptState(transaction.txHash);
      if (state != ReceiptState.pending) {
        await _store.remove(transaction.txHash);
        return state;
      }
      await Future<void>.delayed(interval);
    }
    return ReceiptState.pending;
  }

  Future<void> resumeForWallet(String walletAddress) async {
    final pending = (await _store.loadAll()).where(
      (item) => item.walletAddress.toLowerCase() == walletAddress.toLowerCase(),
    );
    for (final item in pending) {
      unawaited(track(item));
    }
  }
}
