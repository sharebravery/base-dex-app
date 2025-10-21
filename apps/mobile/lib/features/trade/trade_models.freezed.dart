// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trade_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SwapPrice {

 BigInt get sellAmount; BigInt get buyAmount; BigInt get networkFee; DateTime get fetchedAt; Duration get validFor;
/// Create a copy of SwapPrice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SwapPriceCopyWith<SwapPrice> get copyWith => _$SwapPriceCopyWithImpl<SwapPrice>(this as SwapPrice, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SwapPrice&&(identical(other.sellAmount, sellAmount) || other.sellAmount == sellAmount)&&(identical(other.buyAmount, buyAmount) || other.buyAmount == buyAmount)&&(identical(other.networkFee, networkFee) || other.networkFee == networkFee)&&(identical(other.fetchedAt, fetchedAt) || other.fetchedAt == fetchedAt)&&(identical(other.validFor, validFor) || other.validFor == validFor));
}


@override
int get hashCode => Object.hash(runtimeType,sellAmount,buyAmount,networkFee,fetchedAt,validFor);

@override
String toString() {
  return 'SwapPrice(sellAmount: $sellAmount, buyAmount: $buyAmount, networkFee: $networkFee, fetchedAt: $fetchedAt, validFor: $validFor)';
}


}

/// @nodoc
abstract mixin class $SwapPriceCopyWith<$Res>  {
  factory $SwapPriceCopyWith(SwapPrice value, $Res Function(SwapPrice) _then) = _$SwapPriceCopyWithImpl;
@useResult
$Res call({
 BigInt sellAmount, BigInt buyAmount, BigInt networkFee, DateTime fetchedAt, Duration validFor
});




}
/// @nodoc
class _$SwapPriceCopyWithImpl<$Res>
    implements $SwapPriceCopyWith<$Res> {
  _$SwapPriceCopyWithImpl(this._self, this._then);

  final SwapPrice _self;
  final $Res Function(SwapPrice) _then;

/// Create a copy of SwapPrice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sellAmount = null,Object? buyAmount = null,Object? networkFee = null,Object? fetchedAt = null,Object? validFor = null,}) {
  return _then(_self.copyWith(
sellAmount: null == sellAmount ? _self.sellAmount : sellAmount // ignore: cast_nullable_to_non_nullable
as BigInt,buyAmount: null == buyAmount ? _self.buyAmount : buyAmount // ignore: cast_nullable_to_non_nullable
as BigInt,networkFee: null == networkFee ? _self.networkFee : networkFee // ignore: cast_nullable_to_non_nullable
as BigInt,fetchedAt: null == fetchedAt ? _self.fetchedAt : fetchedAt // ignore: cast_nullable_to_non_nullable
as DateTime,validFor: null == validFor ? _self.validFor : validFor // ignore: cast_nullable_to_non_nullable
as Duration,
  ));
}

}


/// Adds pattern-matching-related methods to [SwapPrice].
extension SwapPricePatterns on SwapPrice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SwapPrice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SwapPrice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SwapPrice value)  $default,){
final _that = this;
switch (_that) {
case _SwapPrice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SwapPrice value)?  $default,){
final _that = this;
switch (_that) {
case _SwapPrice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BigInt sellAmount,  BigInt buyAmount,  BigInt networkFee,  DateTime fetchedAt,  Duration validFor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SwapPrice() when $default != null:
return $default(_that.sellAmount,_that.buyAmount,_that.networkFee,_that.fetchedAt,_that.validFor);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BigInt sellAmount,  BigInt buyAmount,  BigInt networkFee,  DateTime fetchedAt,  Duration validFor)  $default,) {final _that = this;
switch (_that) {
case _SwapPrice():
return $default(_that.sellAmount,_that.buyAmount,_that.networkFee,_that.fetchedAt,_that.validFor);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BigInt sellAmount,  BigInt buyAmount,  BigInt networkFee,  DateTime fetchedAt,  Duration validFor)?  $default,) {final _that = this;
switch (_that) {
case _SwapPrice() when $default != null:
return $default(_that.sellAmount,_that.buyAmount,_that.networkFee,_that.fetchedAt,_that.validFor);case _:
  return null;

}
}

}

/// @nodoc


class _SwapPrice implements SwapPrice {
  const _SwapPrice({required this.sellAmount, required this.buyAmount, required this.networkFee, required this.fetchedAt, required this.validFor});
  

@override final  BigInt sellAmount;
@override final  BigInt buyAmount;
@override final  BigInt networkFee;
@override final  DateTime fetchedAt;
@override final  Duration validFor;

/// Create a copy of SwapPrice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SwapPriceCopyWith<_SwapPrice> get copyWith => __$SwapPriceCopyWithImpl<_SwapPrice>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SwapPrice&&(identical(other.sellAmount, sellAmount) || other.sellAmount == sellAmount)&&(identical(other.buyAmount, buyAmount) || other.buyAmount == buyAmount)&&(identical(other.networkFee, networkFee) || other.networkFee == networkFee)&&(identical(other.fetchedAt, fetchedAt) || other.fetchedAt == fetchedAt)&&(identical(other.validFor, validFor) || other.validFor == validFor));
}


@override
int get hashCode => Object.hash(runtimeType,sellAmount,buyAmount,networkFee,fetchedAt,validFor);

@override
String toString() {
  return 'SwapPrice(sellAmount: $sellAmount, buyAmount: $buyAmount, networkFee: $networkFee, fetchedAt: $fetchedAt, validFor: $validFor)';
}


}

/// @nodoc
abstract mixin class _$SwapPriceCopyWith<$Res> implements $SwapPriceCopyWith<$Res> {
  factory _$SwapPriceCopyWith(_SwapPrice value, $Res Function(_SwapPrice) _then) = __$SwapPriceCopyWithImpl;
@override @useResult
$Res call({
 BigInt sellAmount, BigInt buyAmount, BigInt networkFee, DateTime fetchedAt, Duration validFor
});




}
/// @nodoc
class __$SwapPriceCopyWithImpl<$Res>
    implements _$SwapPriceCopyWith<$Res> {
  __$SwapPriceCopyWithImpl(this._self, this._then);

  final _SwapPrice _self;
  final $Res Function(_SwapPrice) _then;

/// Create a copy of SwapPrice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sellAmount = null,Object? buyAmount = null,Object? networkFee = null,Object? fetchedAt = null,Object? validFor = null,}) {
  return _then(_SwapPrice(
sellAmount: null == sellAmount ? _self.sellAmount : sellAmount // ignore: cast_nullable_to_non_nullable
as BigInt,buyAmount: null == buyAmount ? _self.buyAmount : buyAmount // ignore: cast_nullable_to_non_nullable
as BigInt,networkFee: null == networkFee ? _self.networkFee : networkFee // ignore: cast_nullable_to_non_nullable
as BigInt,fetchedAt: null == fetchedAt ? _self.fetchedAt : fetchedAt // ignore: cast_nullable_to_non_nullable
as DateTime,validFor: null == validFor ? _self.validFor : validFor // ignore: cast_nullable_to_non_nullable
as Duration,
  ));
}


}

/// @nodoc
mixin _$SwapQuote {

 BigInt get sellAmount; BigInt get buyAmount; BigInt get minBuyAmount; BigInt get networkFee; String? get allowanceTarget; String get transactionTo; String? get transactionData; BigInt get transactionValue; BigInt get gas; BigInt get gasPrice; List<String> get routeLabels; DateTime get fetchedAt; Duration get validFor;
/// Create a copy of SwapQuote
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SwapQuoteCopyWith<SwapQuote> get copyWith => _$SwapQuoteCopyWithImpl<SwapQuote>(this as SwapQuote, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SwapQuote&&(identical(other.sellAmount, sellAmount) || other.sellAmount == sellAmount)&&(identical(other.buyAmount, buyAmount) || other.buyAmount == buyAmount)&&(identical(other.minBuyAmount, minBuyAmount) || other.minBuyAmount == minBuyAmount)&&(identical(other.networkFee, networkFee) || other.networkFee == networkFee)&&(identical(other.allowanceTarget, allowanceTarget) || other.allowanceTarget == allowanceTarget)&&(identical(other.transactionTo, transactionTo) || other.transactionTo == transactionTo)&&(identical(other.transactionData, transactionData) || other.transactionData == transactionData)&&(identical(other.transactionValue, transactionValue) || other.transactionValue == transactionValue)&&(identical(other.gas, gas) || other.gas == gas)&&(identical(other.gasPrice, gasPrice) || other.gasPrice == gasPrice)&&const DeepCollectionEquality().equals(other.routeLabels, routeLabels)&&(identical(other.fetchedAt, fetchedAt) || other.fetchedAt == fetchedAt)&&(identical(other.validFor, validFor) || other.validFor == validFor));
}


@override
int get hashCode => Object.hash(runtimeType,sellAmount,buyAmount,minBuyAmount,networkFee,allowanceTarget,transactionTo,transactionData,transactionValue,gas,gasPrice,const DeepCollectionEquality().hash(routeLabels),fetchedAt,validFor);

@override
String toString() {
  return 'SwapQuote(sellAmount: $sellAmount, buyAmount: $buyAmount, minBuyAmount: $minBuyAmount, networkFee: $networkFee, allowanceTarget: $allowanceTarget, transactionTo: $transactionTo, transactionData: $transactionData, transactionValue: $transactionValue, gas: $gas, gasPrice: $gasPrice, routeLabels: $routeLabels, fetchedAt: $fetchedAt, validFor: $validFor)';
}


}

/// @nodoc
abstract mixin class $SwapQuoteCopyWith<$Res>  {
  factory $SwapQuoteCopyWith(SwapQuote value, $Res Function(SwapQuote) _then) = _$SwapQuoteCopyWithImpl;
@useResult
$Res call({
 BigInt sellAmount, BigInt buyAmount, BigInt minBuyAmount, BigInt networkFee, String? allowanceTarget, String transactionTo, String? transactionData, BigInt transactionValue, BigInt gas, BigInt gasPrice, List<String> routeLabels, DateTime fetchedAt, Duration validFor
});




}
/// @nodoc
class _$SwapQuoteCopyWithImpl<$Res>
    implements $SwapQuoteCopyWith<$Res> {
  _$SwapQuoteCopyWithImpl(this._self, this._then);

  final SwapQuote _self;
  final $Res Function(SwapQuote) _then;

/// Create a copy of SwapQuote
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sellAmount = null,Object? buyAmount = null,Object? minBuyAmount = null,Object? networkFee = null,Object? allowanceTarget = freezed,Object? transactionTo = null,Object? transactionData = freezed,Object? transactionValue = null,Object? gas = null,Object? gasPrice = null,Object? routeLabels = null,Object? fetchedAt = null,Object? validFor = null,}) {
  return _then(_self.copyWith(
sellAmount: null == sellAmount ? _self.sellAmount : sellAmount // ignore: cast_nullable_to_non_nullable
as BigInt,buyAmount: null == buyAmount ? _self.buyAmount : buyAmount // ignore: cast_nullable_to_non_nullable
as BigInt,minBuyAmount: null == minBuyAmount ? _self.minBuyAmount : minBuyAmount // ignore: cast_nullable_to_non_nullable
as BigInt,networkFee: null == networkFee ? _self.networkFee : networkFee // ignore: cast_nullable_to_non_nullable
as BigInt,allowanceTarget: freezed == allowanceTarget ? _self.allowanceTarget : allowanceTarget // ignore: cast_nullable_to_non_nullable
as String?,transactionTo: null == transactionTo ? _self.transactionTo : transactionTo // ignore: cast_nullable_to_non_nullable
as String,transactionData: freezed == transactionData ? _self.transactionData : transactionData // ignore: cast_nullable_to_non_nullable
as String?,transactionValue: null == transactionValue ? _self.transactionValue : transactionValue // ignore: cast_nullable_to_non_nullable
as BigInt,gas: null == gas ? _self.gas : gas // ignore: cast_nullable_to_non_nullable
as BigInt,gasPrice: null == gasPrice ? _self.gasPrice : gasPrice // ignore: cast_nullable_to_non_nullable
as BigInt,routeLabels: null == routeLabels ? _self.routeLabels : routeLabels // ignore: cast_nullable_to_non_nullable
as List<String>,fetchedAt: null == fetchedAt ? _self.fetchedAt : fetchedAt // ignore: cast_nullable_to_non_nullable
as DateTime,validFor: null == validFor ? _self.validFor : validFor // ignore: cast_nullable_to_non_nullable
as Duration,
  ));
}

}


/// Adds pattern-matching-related methods to [SwapQuote].
extension SwapQuotePatterns on SwapQuote {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SwapQuote value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SwapQuote() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SwapQuote value)  $default,){
final _that = this;
switch (_that) {
case _SwapQuote():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SwapQuote value)?  $default,){
final _that = this;
switch (_that) {
case _SwapQuote() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BigInt sellAmount,  BigInt buyAmount,  BigInt minBuyAmount,  BigInt networkFee,  String? allowanceTarget,  String transactionTo,  String? transactionData,  BigInt transactionValue,  BigInt gas,  BigInt gasPrice,  List<String> routeLabels,  DateTime fetchedAt,  Duration validFor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SwapQuote() when $default != null:
return $default(_that.sellAmount,_that.buyAmount,_that.minBuyAmount,_that.networkFee,_that.allowanceTarget,_that.transactionTo,_that.transactionData,_that.transactionValue,_that.gas,_that.gasPrice,_that.routeLabels,_that.fetchedAt,_that.validFor);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BigInt sellAmount,  BigInt buyAmount,  BigInt minBuyAmount,  BigInt networkFee,  String? allowanceTarget,  String transactionTo,  String? transactionData,  BigInt transactionValue,  BigInt gas,  BigInt gasPrice,  List<String> routeLabels,  DateTime fetchedAt,  Duration validFor)  $default,) {final _that = this;
switch (_that) {
case _SwapQuote():
return $default(_that.sellAmount,_that.buyAmount,_that.minBuyAmount,_that.networkFee,_that.allowanceTarget,_that.transactionTo,_that.transactionData,_that.transactionValue,_that.gas,_that.gasPrice,_that.routeLabels,_that.fetchedAt,_that.validFor);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BigInt sellAmount,  BigInt buyAmount,  BigInt minBuyAmount,  BigInt networkFee,  String? allowanceTarget,  String transactionTo,  String? transactionData,  BigInt transactionValue,  BigInt gas,  BigInt gasPrice,  List<String> routeLabels,  DateTime fetchedAt,  Duration validFor)?  $default,) {final _that = this;
switch (_that) {
case _SwapQuote() when $default != null:
return $default(_that.sellAmount,_that.buyAmount,_that.minBuyAmount,_that.networkFee,_that.allowanceTarget,_that.transactionTo,_that.transactionData,_that.transactionValue,_that.gas,_that.gasPrice,_that.routeLabels,_that.fetchedAt,_that.validFor);case _:
  return null;

}
}

}

/// @nodoc


class _SwapQuote extends SwapQuote {
  const _SwapQuote({required this.sellAmount, required this.buyAmount, required this.minBuyAmount, required this.networkFee, required this.allowanceTarget, required this.transactionTo, required this.transactionData, required this.transactionValue, required this.gas, required this.gasPrice, required final  List<String> routeLabels, required this.fetchedAt, required this.validFor}): _routeLabels = routeLabels,super._();
  

@override final  BigInt sellAmount;
@override final  BigInt buyAmount;
@override final  BigInt minBuyAmount;
@override final  BigInt networkFee;
@override final  String? allowanceTarget;
@override final  String transactionTo;
@override final  String? transactionData;
@override final  BigInt transactionValue;
@override final  BigInt gas;
@override final  BigInt gasPrice;
 final  List<String> _routeLabels;
@override List<String> get routeLabels {
  if (_routeLabels is EqualUnmodifiableListView) return _routeLabels;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_routeLabels);
}

@override final  DateTime fetchedAt;
@override final  Duration validFor;

/// Create a copy of SwapQuote
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SwapQuoteCopyWith<_SwapQuote> get copyWith => __$SwapQuoteCopyWithImpl<_SwapQuote>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SwapQuote&&(identical(other.sellAmount, sellAmount) || other.sellAmount == sellAmount)&&(identical(other.buyAmount, buyAmount) || other.buyAmount == buyAmount)&&(identical(other.minBuyAmount, minBuyAmount) || other.minBuyAmount == minBuyAmount)&&(identical(other.networkFee, networkFee) || other.networkFee == networkFee)&&(identical(other.allowanceTarget, allowanceTarget) || other.allowanceTarget == allowanceTarget)&&(identical(other.transactionTo, transactionTo) || other.transactionTo == transactionTo)&&(identical(other.transactionData, transactionData) || other.transactionData == transactionData)&&(identical(other.transactionValue, transactionValue) || other.transactionValue == transactionValue)&&(identical(other.gas, gas) || other.gas == gas)&&(identical(other.gasPrice, gasPrice) || other.gasPrice == gasPrice)&&const DeepCollectionEquality().equals(other._routeLabels, _routeLabels)&&(identical(other.fetchedAt, fetchedAt) || other.fetchedAt == fetchedAt)&&(identical(other.validFor, validFor) || other.validFor == validFor));
}


@override
int get hashCode => Object.hash(runtimeType,sellAmount,buyAmount,minBuyAmount,networkFee,allowanceTarget,transactionTo,transactionData,transactionValue,gas,gasPrice,const DeepCollectionEquality().hash(_routeLabels),fetchedAt,validFor);

@override
String toString() {
  return 'SwapQuote(sellAmount: $sellAmount, buyAmount: $buyAmount, minBuyAmount: $minBuyAmount, networkFee: $networkFee, allowanceTarget: $allowanceTarget, transactionTo: $transactionTo, transactionData: $transactionData, transactionValue: $transactionValue, gas: $gas, gasPrice: $gasPrice, routeLabels: $routeLabels, fetchedAt: $fetchedAt, validFor: $validFor)';
}


}

/// @nodoc
abstract mixin class _$SwapQuoteCopyWith<$Res> implements $SwapQuoteCopyWith<$Res> {
  factory _$SwapQuoteCopyWith(_SwapQuote value, $Res Function(_SwapQuote) _then) = __$SwapQuoteCopyWithImpl;
@override @useResult
$Res call({
 BigInt sellAmount, BigInt buyAmount, BigInt minBuyAmount, BigInt networkFee, String? allowanceTarget, String transactionTo, String? transactionData, BigInt transactionValue, BigInt gas, BigInt gasPrice, List<String> routeLabels, DateTime fetchedAt, Duration validFor
});




}
/// @nodoc
class __$SwapQuoteCopyWithImpl<$Res>
    implements _$SwapQuoteCopyWith<$Res> {
  __$SwapQuoteCopyWithImpl(this._self, this._then);

  final _SwapQuote _self;
  final $Res Function(_SwapQuote) _then;

/// Create a copy of SwapQuote
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sellAmount = null,Object? buyAmount = null,Object? minBuyAmount = null,Object? networkFee = null,Object? allowanceTarget = freezed,Object? transactionTo = null,Object? transactionData = freezed,Object? transactionValue = null,Object? gas = null,Object? gasPrice = null,Object? routeLabels = null,Object? fetchedAt = null,Object? validFor = null,}) {
  return _then(_SwapQuote(
sellAmount: null == sellAmount ? _self.sellAmount : sellAmount // ignore: cast_nullable_to_non_nullable
as BigInt,buyAmount: null == buyAmount ? _self.buyAmount : buyAmount // ignore: cast_nullable_to_non_nullable
as BigInt,minBuyAmount: null == minBuyAmount ? _self.minBuyAmount : minBuyAmount // ignore: cast_nullable_to_non_nullable
as BigInt,networkFee: null == networkFee ? _self.networkFee : networkFee // ignore: cast_nullable_to_non_nullable
as BigInt,allowanceTarget: freezed == allowanceTarget ? _self.allowanceTarget : allowanceTarget // ignore: cast_nullable_to_non_nullable
as String?,transactionTo: null == transactionTo ? _self.transactionTo : transactionTo // ignore: cast_nullable_to_non_nullable
as String,transactionData: freezed == transactionData ? _self.transactionData : transactionData // ignore: cast_nullable_to_non_nullable
as String?,transactionValue: null == transactionValue ? _self.transactionValue : transactionValue // ignore: cast_nullable_to_non_nullable
as BigInt,gas: null == gas ? _self.gas : gas // ignore: cast_nullable_to_non_nullable
as BigInt,gasPrice: null == gasPrice ? _self.gasPrice : gasPrice // ignore: cast_nullable_to_non_nullable
as BigInt,routeLabels: null == routeLabels ? _self._routeLabels : routeLabels // ignore: cast_nullable_to_non_nullable
as List<String>,fetchedAt: null == fetchedAt ? _self.fetchedAt : fetchedAt // ignore: cast_nullable_to_non_nullable
as DateTime,validFor: null == validFor ? _self.validFor : validFor // ignore: cast_nullable_to_non_nullable
as Duration,
  ));
}


}

/// @nodoc
mixin _$TradeState {

 String get amountText; int get slippageBps; SwapRequest? get request; SwapPrice? get price; SwapQuote? get quote; bool get loadingPrice; bool get loadingQuote; String? get errorCode;
/// Create a copy of TradeState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TradeStateCopyWith<TradeState> get copyWith => _$TradeStateCopyWithImpl<TradeState>(this as TradeState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TradeState&&(identical(other.amountText, amountText) || other.amountText == amountText)&&(identical(other.slippageBps, slippageBps) || other.slippageBps == slippageBps)&&(identical(other.request, request) || other.request == request)&&(identical(other.price, price) || other.price == price)&&(identical(other.quote, quote) || other.quote == quote)&&(identical(other.loadingPrice, loadingPrice) || other.loadingPrice == loadingPrice)&&(identical(other.loadingQuote, loadingQuote) || other.loadingQuote == loadingQuote)&&(identical(other.errorCode, errorCode) || other.errorCode == errorCode));
}


@override
int get hashCode => Object.hash(runtimeType,amountText,slippageBps,request,price,quote,loadingPrice,loadingQuote,errorCode);

@override
String toString() {
  return 'TradeState(amountText: $amountText, slippageBps: $slippageBps, request: $request, price: $price, quote: $quote, loadingPrice: $loadingPrice, loadingQuote: $loadingQuote, errorCode: $errorCode)';
}


}

/// @nodoc
abstract mixin class $TradeStateCopyWith<$Res>  {
  factory $TradeStateCopyWith(TradeState value, $Res Function(TradeState) _then) = _$TradeStateCopyWithImpl;
@useResult
$Res call({
 String amountText, int slippageBps, SwapRequest? request, SwapPrice? price, SwapQuote? quote, bool loadingPrice, bool loadingQuote, String? errorCode
});


$SwapPriceCopyWith<$Res>? get price;$SwapQuoteCopyWith<$Res>? get quote;

}
/// @nodoc
class _$TradeStateCopyWithImpl<$Res>
    implements $TradeStateCopyWith<$Res> {
  _$TradeStateCopyWithImpl(this._self, this._then);

  final TradeState _self;
  final $Res Function(TradeState) _then;

/// Create a copy of TradeState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? amountText = null,Object? slippageBps = null,Object? request = freezed,Object? price = freezed,Object? quote = freezed,Object? loadingPrice = null,Object? loadingQuote = null,Object? errorCode = freezed,}) {
  return _then(_self.copyWith(
amountText: null == amountText ? _self.amountText : amountText // ignore: cast_nullable_to_non_nullable
as String,slippageBps: null == slippageBps ? _self.slippageBps : slippageBps // ignore: cast_nullable_to_non_nullable
as int,request: freezed == request ? _self.request : request // ignore: cast_nullable_to_non_nullable
as SwapRequest?,price: freezed == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as SwapPrice?,quote: freezed == quote ? _self.quote : quote // ignore: cast_nullable_to_non_nullable
as SwapQuote?,loadingPrice: null == loadingPrice ? _self.loadingPrice : loadingPrice // ignore: cast_nullable_to_non_nullable
as bool,loadingQuote: null == loadingQuote ? _self.loadingQuote : loadingQuote // ignore: cast_nullable_to_non_nullable
as bool,errorCode: freezed == errorCode ? _self.errorCode : errorCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of TradeState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SwapPriceCopyWith<$Res>? get price {
    if (_self.price == null) {
    return null;
  }

  return $SwapPriceCopyWith<$Res>(_self.price!, (value) {
    return _then(_self.copyWith(price: value));
  });
}/// Create a copy of TradeState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SwapQuoteCopyWith<$Res>? get quote {
    if (_self.quote == null) {
    return null;
  }

  return $SwapQuoteCopyWith<$Res>(_self.quote!, (value) {
    return _then(_self.copyWith(quote: value));
  });
}
}


/// Adds pattern-matching-related methods to [TradeState].
extension TradeStatePatterns on TradeState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TradeState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TradeState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TradeState value)  $default,){
final _that = this;
switch (_that) {
case _TradeState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TradeState value)?  $default,){
final _that = this;
switch (_that) {
case _TradeState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String amountText,  int slippageBps,  SwapRequest? request,  SwapPrice? price,  SwapQuote? quote,  bool loadingPrice,  bool loadingQuote,  String? errorCode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TradeState() when $default != null:
return $default(_that.amountText,_that.slippageBps,_that.request,_that.price,_that.quote,_that.loadingPrice,_that.loadingQuote,_that.errorCode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String amountText,  int slippageBps,  SwapRequest? request,  SwapPrice? price,  SwapQuote? quote,  bool loadingPrice,  bool loadingQuote,  String? errorCode)  $default,) {final _that = this;
switch (_that) {
case _TradeState():
return $default(_that.amountText,_that.slippageBps,_that.request,_that.price,_that.quote,_that.loadingPrice,_that.loadingQuote,_that.errorCode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String amountText,  int slippageBps,  SwapRequest? request,  SwapPrice? price,  SwapQuote? quote,  bool loadingPrice,  bool loadingQuote,  String? errorCode)?  $default,) {final _that = this;
switch (_that) {
case _TradeState() when $default != null:
return $default(_that.amountText,_that.slippageBps,_that.request,_that.price,_that.quote,_that.loadingPrice,_that.loadingQuote,_that.errorCode);case _:
  return null;

}
}

}

/// @nodoc


class _TradeState implements TradeState {
  const _TradeState({this.amountText = '', this.slippageBps = 50, this.request, this.price, this.quote, this.loadingPrice = false, this.loadingQuote = false, this.errorCode});
  

@override@JsonKey() final  String amountText;
@override@JsonKey() final  int slippageBps;
@override final  SwapRequest? request;
@override final  SwapPrice? price;
@override final  SwapQuote? quote;
@override@JsonKey() final  bool loadingPrice;
@override@JsonKey() final  bool loadingQuote;
@override final  String? errorCode;

/// Create a copy of TradeState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TradeStateCopyWith<_TradeState> get copyWith => __$TradeStateCopyWithImpl<_TradeState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TradeState&&(identical(other.amountText, amountText) || other.amountText == amountText)&&(identical(other.slippageBps, slippageBps) || other.slippageBps == slippageBps)&&(identical(other.request, request) || other.request == request)&&(identical(other.price, price) || other.price == price)&&(identical(other.quote, quote) || other.quote == quote)&&(identical(other.loadingPrice, loadingPrice) || other.loadingPrice == loadingPrice)&&(identical(other.loadingQuote, loadingQuote) || other.loadingQuote == loadingQuote)&&(identical(other.errorCode, errorCode) || other.errorCode == errorCode));
}


@override
int get hashCode => Object.hash(runtimeType,amountText,slippageBps,request,price,quote,loadingPrice,loadingQuote,errorCode);

@override
String toString() {
  return 'TradeState(amountText: $amountText, slippageBps: $slippageBps, request: $request, price: $price, quote: $quote, loadingPrice: $loadingPrice, loadingQuote: $loadingQuote, errorCode: $errorCode)';
}


}

/// @nodoc
abstract mixin class _$TradeStateCopyWith<$Res> implements $TradeStateCopyWith<$Res> {
  factory _$TradeStateCopyWith(_TradeState value, $Res Function(_TradeState) _then) = __$TradeStateCopyWithImpl;
@override @useResult
$Res call({
 String amountText, int slippageBps, SwapRequest? request, SwapPrice? price, SwapQuote? quote, bool loadingPrice, bool loadingQuote, String? errorCode
});


@override $SwapPriceCopyWith<$Res>? get price;@override $SwapQuoteCopyWith<$Res>? get quote;

}
/// @nodoc
class __$TradeStateCopyWithImpl<$Res>
    implements _$TradeStateCopyWith<$Res> {
  __$TradeStateCopyWithImpl(this._self, this._then);

  final _TradeState _self;
  final $Res Function(_TradeState) _then;

/// Create a copy of TradeState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? amountText = null,Object? slippageBps = null,Object? request = freezed,Object? price = freezed,Object? quote = freezed,Object? loadingPrice = null,Object? loadingQuote = null,Object? errorCode = freezed,}) {
  return _then(_TradeState(
amountText: null == amountText ? _self.amountText : amountText // ignore: cast_nullable_to_non_nullable
as String,slippageBps: null == slippageBps ? _self.slippageBps : slippageBps // ignore: cast_nullable_to_non_nullable
as int,request: freezed == request ? _self.request : request // ignore: cast_nullable_to_non_nullable
as SwapRequest?,price: freezed == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as SwapPrice?,quote: freezed == quote ? _self.quote : quote // ignore: cast_nullable_to_non_nullable
as SwapQuote?,loadingPrice: null == loadingPrice ? _self.loadingPrice : loadingPrice // ignore: cast_nullable_to_non_nullable
as bool,loadingQuote: null == loadingQuote ? _self.loadingQuote : loadingQuote // ignore: cast_nullable_to_non_nullable
as bool,errorCode: freezed == errorCode ? _self.errorCode : errorCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of TradeState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SwapPriceCopyWith<$Res>? get price {
    if (_self.price == null) {
    return null;
  }

  return $SwapPriceCopyWith<$Res>(_self.price!, (value) {
    return _then(_self.copyWith(price: value));
  });
}/// Create a copy of TradeState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SwapQuoteCopyWith<$Res>? get quote {
    if (_self.quote == null) {
    return null;
  }

  return $SwapQuoteCopyWith<$Res>(_self.quote!, (value) {
    return _then(_self.copyWith(quote: value));
  });
}
}

// dart format on
