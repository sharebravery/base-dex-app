// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PendingTransaction _$PendingTransactionFromJson(Map<String, dynamic> json) =>
    _PendingTransaction(
      txHash: json['txHash'] as String,
      walletAddress: json['walletAddress'] as String,
      operation: $enumDecode(_$PendingOperationEnumMap, json['operation']),
      symbol: json['symbol'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$PendingTransactionToJson(_PendingTransaction instance) =>
    <String, dynamic>{
      'txHash': instance.txHash,
      'walletAddress': instance.walletAddress,
      'operation': _$PendingOperationEnumMap[instance.operation]!,
      'symbol': instance.symbol,
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$PendingOperationEnumMap = {
  PendingOperation.approve: 'approve',
  PendingOperation.swap: 'swap',
  PendingOperation.withdraw: 'withdraw',
};
