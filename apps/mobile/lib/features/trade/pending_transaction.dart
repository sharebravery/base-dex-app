import 'package:freezed_annotation/freezed_annotation.dart';
part 'pending_transaction.freezed.dart';
part 'pending_transaction.g.dart';

enum PendingOperation { approve, swap, withdraw }

@freezed
abstract class PendingTransaction with _$PendingTransaction {
  const factory PendingTransaction({
    required String txHash,
    required String walletAddress,
    required PendingOperation operation,
    required String symbol,
    required DateTime createdAt,
  }) = _PendingTransaction;

  factory PendingTransaction.fromJson(Map<String, Object?> json) =>
      _$PendingTransactionFromJson(json);
}
