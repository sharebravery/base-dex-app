import 'dart:convert';
import 'package:dex_app/features/trade/pending_transaction.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class PendingTransactionStore {
  PendingTransactionStore(this._preferences);
  final SharedPreferencesAsync _preferences;
  static const _key = 'pending_transactions_v1';

  Future<List<PendingTransaction>> loadAll() async {
    final raw = await _preferences.getString(_key);
    if (raw == null) return const [];
    final list = jsonDecode(raw) as List<Object?>;
    return list
        .map((item) => PendingTransaction.fromJson(item! as Map<String, Object?>))
        .toList(growable: false);
  }

  Future<void> save(PendingTransaction value) async {
    final current = await loadAll();
    final next = [
      ...current.where((item) => item.txHash != value.txHash),
      value,
    ];
    await _preferences.setString(
      _key,
      jsonEncode(next.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> remove(String txHash) async {
    final next = (await loadAll()).where((item) => item.txHash != txHash).toList();
    await _preferences.setString(
      _key,
      jsonEncode(next.map((item) => item.toJson()).toList()),
    );
  }
}
