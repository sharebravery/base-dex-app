import 'package:dex_app/features/market/market_models.dart';
import 'package:flutter/widgets.dart';

class CandlestickChart extends StatelessWidget {
  const CandlestickChart({required this.candles, super.key});

  final List<Candle> candles;

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
