import 'package:decimal/decimal.dart';
import 'package:dex_app/core/widgets/glass_card.dart';
import 'package:dex_app/features/market/market_models.dart';
import 'package:dex_app/features/market/market_providers.dart';
import 'package:dex_app/features/market/widgets/market_asset_tile.dart';
import 'package:dex_app/features/market/widgets/market_hero_card.dart';
import 'package:dex_app/features/market/widgets/trending_carousel.dart';
import 'package:dex_app/l10n/l10n_extension.dart';
import 'package:dex_app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Filter chip options for the main list. `null` means "no filter".
class _CategoryFilter {
  const _CategoryFilter(this.category, this.labelBuilder);
  final AssetCategory? category;
  final String Function(BuildContext context) labelBuilder;
}

final _filters = <_CategoryFilter>[
  _CategoryFilter(null, (c) => c.l10n.categoryAll),
  _CategoryFilter(AssetCategory.layer1, (c) => c.l10n.categoryLayer1),
  _CategoryFilter(AssetCategory.layer2, (c) => c.l10n.categoryLayer2),
  _CategoryFilter(AssetCategory.defi, (c) => c.l10n.categoryDefi),
  _CategoryFilter(AssetCategory.meme, (c) => c.l10n.categoryMeme),
  _CategoryFilter(AssetCategory.stable, (c) => c.l10n.categoryStable),
];

class MarketScreen extends ConsumerStatefulWidget {
  const MarketScreen({super.key});

  @override
  ConsumerState<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends ConsumerState<MarketScreen> {
  AssetCategory? _category;
  String _query = '';
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(marketAssetsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.market)),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(marketAssetsProvider);
            ref.invalidate(sparklinesProvider);
            await ref.read(marketAssetsProvider.future);
          },
          child: async.when(
            data: (assets) => _content(context, assets),
            loading: () => _skeleton(),
            error: (error, _) => _errorState(context, error),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, List<MarketAsset> assets) {
    final gainers = [
      for (final a in assets)
        if (a.volume24hUsd > Decimal.zero) a,
    ]..sort((a, b) => b.change24hPercent.compareTo(a.change24hPercent));

    final filtered = _applyFilters(assets);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          sliver: SliverToBoxAdapter(child: MarketHeroCard(assets: assets)),
        ),
        SliverToBoxAdapter(
          child: TrendingCarousel.gainers(
            title: context.l10n.topGainers,
            assets: gainers,
            onTap: (asset) => context.push('/market/${asset.id}'),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverToBoxAdapter(
          child: TrendingCarousel.losers(
            title: context.l10n.topLosers,
            assets: gainers,
            onTap: (asset) => context.push('/market/${asset.id}'),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        SliverPersistentHeader(
          pinned: true,
          delegate: _StickyFilterHeader(
            searchController: _searchController,
            query: _query,
            category: _category,
            onQuery: (v) => setState(() => _query = v),
            onCategory: (c) => setState(() => _category = c),
          ),
        ),
        if (filtered.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Center(
                child: Text(
                  context.l10n.noMatchingAssets,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            sliver: SliverList.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final asset = filtered[index];
                return GlassCard(
                  padding: EdgeInsets.zero,
                  onTap: () => context.push('/market/${asset.id}'),
                  child: MarketAssetTile(asset: asset),
                );
              },
            ),
          ),
      ],
    );
  }

  List<MarketAsset> _applyFilters(List<MarketAsset> assets) {
    final q = _query.trim().toLowerCase();
    return [
      for (final a in assets)
        if ((_category == null || a.category == _category) &&
            (q.isEmpty ||
                a.baseSymbol.toLowerCase().contains(q) ||
                a.name.toLowerCase().contains(q)))
          a,
    ];
  }

  Widget _skeleton() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 8,
      physics: const AlwaysScrollableScrollPhysics(),
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => const _SkeletonRow(),
    );
  }

  Widget _errorState(BuildContext context, Object error) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        _ErrorPanel(
          message: error.toString(),
          onRetry: () => ref.invalidate(marketAssetsProvider),
        ),
      ],
    );
  }
}

class _StickyFilterHeader extends SliverPersistentHeaderDelegate {
  _StickyFilterHeader({
    required this.searchController,
    required this.query,
    required this.category,
    required this.onQuery,
    required this.onCategory,
  });

  final TextEditingController searchController;
  final String query;
  final AssetCategory? category;
  final ValueChanged<String> onQuery;
  final ValueChanged<AssetCategory?> onCategory;

  @override
  double get minExtent => 108;
  @override
  double get maxExtent => 108;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // Background matches the scaffold so the header doesn't look like a
    // floating pill while pinned.
    return Container(
      color: AppColors.bg,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 44,
            child: TextField(
              controller: searchController,
              onChanged: onQuery,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: context.l10n.searchAssets,
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          searchController.clear();
                          onQuery('');
                        },
                      ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final f = _filters[i];
                final selected = f.category == category;
                return FilterChip(
                  selected: selected,
                  onSelected: (_) => onCategory(f.category),
                  label: Text(f.labelBuilder(context)),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyFilterHeader oldDelegate) {
    return oldDelegate.query != query || oldDelegate.category != category;
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    return GlassCard(
      child: Row(
        children: [
          CircleAvatar(radius: 16, backgroundColor: base),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 12, width: 80, color: base),
                const SizedBox(height: 6),
                Container(height: 10, width: 120, color: base),
              ],
            ),
          ),
          Container(height: 12, width: 60, color: base),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.wifi_off, color: scheme.error, size: 32),
          const SizedBox(height: 12),
          Text(
            l10n.marketUnavailable,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: onRetry,
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }
}
