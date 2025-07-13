import 'package:dex_app/features/market/market_models.dart';
import 'package:dex_app/l10n/l10n_extension.dart';
import 'package:flutter/material.dart';

class MarketAssetTile extends StatelessWidget {
  const MarketAssetTile({required this.asset, this.onTap, super.key});

  final MarketAsset asset;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(asset.baseSymbol),
      subtitle: Text(asset.tradable ? context.l10n.tradable : context.l10n.marketDataOnly),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('\$${asset.priceUsd.toString()}'),
          Text('${asset.change24hPercent}%'),
        ],
      ),
    );
  }
}
