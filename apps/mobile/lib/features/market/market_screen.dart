import 'package:dex_app/features/market/market_controller.dart';
import 'package:dex_app/features/market/widgets/market_asset_tile.dart';
import 'package:dex_app/l10n/l10n_extension.dart';
import 'package:flutter/material.dart';

class MarketScreen extends StatelessWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final assets = const MarketController().loadFixtures();
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.market)),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: assets.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) => Card(
            child: MarketAssetTile(asset: assets[index]),
          ),
        ),
      ),
    );
  }
}
