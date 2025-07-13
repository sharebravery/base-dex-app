import 'package:dex_app/features/market/market_models.dart';
import 'package:dex_app/l10n/l10n_extension.dart';
import 'package:flutter/material.dart';

class PairDetailScreen extends StatelessWidget {
  const PairDetailScreen({required this.asset, super.key});

  final MarketAsset asset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(asset.tradable ? '${asset.baseSymbol} / ${asset.quoteSymbol}' : asset.baseSymbol),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('\$${asset.priceUsd}', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 16),
              Expanded(child: Card(child: Center(child: Text(context.l10n.chart)))),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: asset.tradable ? () {} : null,
                child: Text(asset.tradable ? context.l10n.swap : context.l10n.marketDataOnly),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
