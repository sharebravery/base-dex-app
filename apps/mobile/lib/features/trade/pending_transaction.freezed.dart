// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pending_transaction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PendingTransaction {

 String get txHash; String get walletAddress; PendingOperation get operation; String get symbol; DateTime get createdAt;
/// Create a copy of PendingTransaction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PendingTransactionCopyWith<PendingTransaction> get copyWith => _$PendingTransactionCopyWithImpl<PendingTransaction>(this as PendingTransaction, _$identity);

  /// Serializes this PendingTransaction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PendingTransaction&&(identical(other.txHash, txHash) || other.txHash == txHash)&&(identical(other.walletAddress, walletAddress) || other.walletAddress == walletAddress)&&(identical(other.operation, operation) || other.operation == operation)&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,txHash,walletAddress,operation,symbol,createdAt);

@override
String toString() {
  return 'PendingTransaction(txHash: $txHash, walletAddress: $walletAddress, operation: $operation, symbol: $symbol, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $PendingTransactionCopyWith<$Res>  {
  factory $PendingTransactionCopyWith(PendingTransaction value, $Res Function(PendingTransaction) _then) = _$PendingTransactionCopyWithImpl;
@useResult
$Res call({
 String txHash, String walletAddress, PendingOperation operation, String symbol, DateTime createdAt
});




}
/// @nodoc
class _$PendingTransactionCopyWithImpl<$Res>
    implements $PendingTransactionCopyWith<$Res> {
  _$PendingTransactionCopyWithImpl(this._self, this._then);

  final PendingTransaction _self;
  final $Res Function(PendingTransaction) _then;

/// Create a copy of PendingTransaction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? txHash = null,Object? walletAddress = null,Object? operation = null,Object? symbol = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
txHash: null == txHash ? _self.txHash : txHash // ignore: cast_nullable_to_non_nullable
as String,walletAddress: null == walletAddress ? _self.walletAddress : walletAddress // ignore: cast_nullable_to_non_nullable
as String,operation: null == operation ? _self.operation : operation // ignore: cast_nullable_to_non_nullable
as PendingOperation,symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [PendingTransaction].
extension PendingTransactionPatterns on PendingTransaction {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PendingTransaction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PendingTransaction() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PendingTransaction value)  $default,){
final _that = this;
switch (_that) {
case _PendingTransaction():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PendingTransaction value)?  $default,){
final _that = this;
switch (_that) {
case _PendingTransaction() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String txHash,  String walletAddress,  PendingOperation operation,  String symbol,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PendingTransaction() when $default != null:
return $default(_that.txHash,_that.walletAddress,_that.operation,_that.symbol,_that.createdAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String txHash,  String walletAddress,  PendingOperation operation,  String symbol,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _PendingTransaction():
return $default(_that.txHash,_that.walletAddress,_that.operation,_that.symbol,_that.createdAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String txHash,  String walletAddress,  PendingOperation operation,  String symbol,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _PendingTransaction() when $default != null:
return $default(_that.txHash,_that.walletAddress,_that.operation,_that.symbol,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PendingTransaction implements PendingTransaction {
  const _PendingTransaction({required this.txHash, required this.walletAddress, required this.operation, required this.symbol, required this.createdAt});
  factory _PendingTransaction.fromJson(Map<String, dynamic> json) => _$PendingTransactionFromJson(json);

@override final  String txHash;
@override final  String walletAddress;
@override final  PendingOperation operation;
@override final  String symbol;
@override final  DateTime createdAt;

/// Create a copy of PendingTransaction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PendingTransactionCopyWith<_PendingTransaction> get copyWith => __$PendingTransactionCopyWithImpl<_PendingTransaction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PendingTransactionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PendingTransaction&&(identical(other.txHash, txHash) || other.txHash == txHash)&&(identical(other.walletAddress, walletAddress) || other.walletAddress == walletAddress)&&(identical(other.operation, operation) || other.operation == operation)&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,txHash,walletAddress,operation,symbol,createdAt);

@override
String toString() {
  return 'PendingTransaction(txHash: $txHash, walletAddress: $walletAddress, operation: $operation, symbol: $symbol, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$PendingTransactionCopyWith<$Res> implements $PendingTransactionCopyWith<$Res> {
  factory _$PendingTransactionCopyWith(_PendingTransaction value, $Res Function(_PendingTransaction) _then) = __$PendingTransactionCopyWithImpl;
@override @useResult
$Res call({
 String txHash, String walletAddress, PendingOperation operation, String symbol, DateTime createdAt
});




}
/// @nodoc
class __$PendingTransactionCopyWithImpl<$Res>
    implements _$PendingTransactionCopyWith<$Res> {
  __$PendingTransactionCopyWithImpl(this._self, this._then);

  final _PendingTransaction _self;
  final $Res Function(_PendingTransaction) _then;

/// Create a copy of PendingTransaction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? txHash = null,Object? walletAddress = null,Object? operation = null,Object? symbol = null,Object? createdAt = null,}) {
  return _then(_PendingTransaction(
txHash: null == txHash ? _self.txHash : txHash // ignore: cast_nullable_to_non_nullable
as String,walletAddress: null == walletAddress ? _self.walletAddress : walletAddress // ignore: cast_nullable_to_non_nullable
as String,operation: null == operation ? _self.operation : operation // ignore: cast_nullable_to_non_nullable
as PendingOperation,symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
