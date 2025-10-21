import 'package:dio/dio.dart';
import 'package:dex_app/features/trade/trade_models.dart';

abstract interface class SwapRepository {
  Future<SwapPrice> getPrice(SwapRequest request);
  Future<SwapQuote> getQuote(SwapRequest request);
}

final class ApiSwapRepository implements SwapRepository {
  ApiSwapRepository(this._dio);
  final Dio _dio;

  Map<String, Object> _body(SwapRequest request) => {
        'chainId': 8453,
        'sellToken': request.sellToken.address,
        'buyToken': request.buyToken.address,
        'sellAmount': request.sellAmount.toString(),
        'taker': request.taker,
        'slippageBps': request.slippageBps,
      };

  @override
  Future<SwapPrice> getPrice(SwapRequest request) async {
    final response = await _dio.post<Map<String, Object?>>('/v1/swap/price', data: _body(request));
    final json = response.data!;
    return SwapPrice(
      sellAmount: BigInt.parse(json['sellAmount']! as String),
      buyAmount: BigInt.parse(json['buyAmount']! as String),
      networkFee: BigInt.parse(json['networkFee']! as String),
      fetchedAt: DateTime.parse(json['fetchedAt']! as String),
      validFor: Duration(seconds: json['validForSeconds']! as int),
    );
  }

  @override
  Future<SwapQuote> getQuote(SwapRequest request) async {
    final response = await _dio.post<Map<String, Object?>>('/v1/swap/quote', data: _body(request));
    final json = response.data!;
    return SwapQuote(
      sellAmount: BigInt.parse(json['sellAmount']! as String),
      buyAmount: BigInt.parse(json['buyAmount']! as String),
      minBuyAmount: BigInt.parse(json['minBuyAmount']! as String),
      networkFee: BigInt.parse(json['networkFee']! as String),
      allowanceTarget: json['allowanceTarget'] as String?,
      transactionTo: json['transactionTo']! as String,
      transactionData: json['transactionData'] as String?,
      transactionValue: BigInt.parse(json['transactionValue']! as String),
      gas: BigInt.parse(json['gas']! as String),
      gasPrice: BigInt.parse(json['gasPrice']! as String),
      routeLabels: (json['routeLabels']! as List<Object?>).cast<String>(),
      fetchedAt: DateTime.parse(json['fetchedAt']! as String),
      validFor: Duration(seconds: json['validForSeconds']! as int),
    );
  }
}
