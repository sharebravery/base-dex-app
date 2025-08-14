import 'package:dex_app/features/portfolio/portfolio_models.dart';
import 'package:dex_app/features/portfolio/portfolio_providers.dart';
import 'package:dex_app/l10n/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({required this.snapshot, super.key});
  final PortfolioSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.portfolio)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('\$${snapshot.totalValueUsd}', style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 24),
            for (final holding in snapshot.holdings)
              ListTile(
                title: Text(holding.symbol),
                subtitle: Text(holding.amount.toString()),
                trailing: Text('\$${holding.valueUsd}'),
              ),
          ],
        ),
      ),
    );
  }
}

class PortfolioRouteScreen extends ConsumerWidget {
  const PortfolioRouteScreen({required this.address, super.key});
  final String address;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(portfolioSnapshotProvider(address)).when(
          data: (snapshot) => PortfolioScreen(snapshot: snapshot),
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => Scaffold(
            body: Center(child: Text(error.toString())),
          ),
        );
  }
}
