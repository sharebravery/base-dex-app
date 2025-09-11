import 'package:dex_app/features/portfolio/activity_models.dart';
import 'package:dex_app/features/trade/pending_transaction.dart';
import 'package:dex_app/features/trade/pending_transaction_store.dart';
import 'package:dio/dio.dart';

final class ActivityController {
  ActivityController(this._store, this._dio);
  final PendingTransactionStore _store;
  final Dio _dio;

  Future<List<ActivityItem>> load() async {
    final pending = await _store.loadAll();
    final serverResponse = await _dio.get<Map<String, Object?>>('/v1/trades');
    final serverRows = (serverResponse.data!['trades'] as List<Object?>)
        .cast<Map<String, Object?>>();

    final pendingItems = pending.map(_pendingToActivity).toList();
    final serverItems = serverRows.map(_serverToActivity).toList();

    return mergeActivity(pendingItems, serverItems);
  }

  ActivityItem _pendingToActivity(PendingTransaction p) => ActivityItem(
        type: _pendingOperationToActivityType(p.operation),
        status: ActivityStatus.pending,
        title: p.symbol,
        txHash: p.txHash,
        timestamp: p.createdAt,
      );

  ActivityItem _serverToActivity(Map<String, Object?> row) => ActivityItem(
        type: ActivityType.swap,
        status: ActivityStatus.confirmed,
        title: '${row['sellToken']} → ${row['buyToken']}',
        txHash: row['txHash']! as String,
        timestamp: DateTime.parse(row['executedAt']! as String),
      );

  ActivityType _pendingOperationToActivityType(PendingOperation op) =>
      switch (op) {
        PendingOperation.approve => ActivityType.approve,
        PendingOperation.swap => ActivityType.swap,
        PendingOperation.withdraw => ActivityType.withdraw,
      };
}

/// Merge two lists of ActivityItem by lowercase txHash, preferring confirmed
/// (server) rows over pending (local) rows, and sorting descending by
/// timestamp. Extracted as a pure function so unit tests can exercise the
/// merge/dedup/sort behavior without spinning up an HTTP client or storage.
List<ActivityItem> mergeActivity(
  List<ActivityItem> pending,
  List<ActivityItem> confirmed,
) {
  final byHash = <String, ActivityItem>{};
  for (final item in pending) {
    byHash[item.txHash.toLowerCase()] = item;
  }
  for (final item in confirmed) {
    byHash[item.txHash.toLowerCase()] = item;
  }
  final list = byHash.values.toList();
  list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return list;
}
