import 'package:dex_app/core/widgets/glass_card.dart';
import 'package:dex_app/features/market/market_models.dart';
import 'package:dex_app/features/market/market_providers.dart';
import 'package:dex_app/features/market/widgets/market_asset_tile.dart';
import 'package:dex_app/l10n/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MarketScreen extends ConsumerWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(marketAssetsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.market)),
      body: SafeArea(
        child: async.when(
          data: (assets) => _list(context, assets),
          error: (err, _) => _list(context, MarketAsset.fixtures),
          loading: () => _list(context, MarketAsset.fixtures),
        ),
      ),
    );
  }

  Widget _list(BuildContext context, List<MarketAsset> assets) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: assets.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final asset = assets[index];
        return GlassCard(
          padding: EdgeInsets.zero,
          onTap: () => context.push('/market/${asset.id}'),
          child: MarketAssetTile(asset: asset),
        );
      },
    );
  }
}
