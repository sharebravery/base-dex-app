import 'package:decimal/decimal.dart';
import 'package:dex_app/core/widgets/glass_card.dart';
import 'package:dex_app/core/widgets/gradient_button.dart';
import 'package:dex_app/features/portfolio/portfolio_models.dart';
import 'package:dex_app/features/portfolio/portfolio_providers.dart';
import 'package:dex_app/l10n/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
            GlassCard(
              elevated: true,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.portfolio,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${_format(snapshot.totalValueUsd)}',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GradientButton(
                    icon: Icons.download,
                    onPressed: () => context.push('/portfolio/deposit'),
                    child: Text(context.l10n.deposit),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/portfolio/withdraw'),
                    icon: const Icon(Icons.upload),
                    label: Text(context.l10n.withdraw),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.push('/portfolio/activity'),
              icon: const Icon(Icons.history),
              label: Text(context.l10n.activity),
            ),
            const SizedBox(height: 24),
            for (final holding in snapshot.holdings) ...[
              GlassCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            holding.symbol,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _format(holding.amount),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '\$${_format(holding.valueUsd)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  String _format(Decimal value) {
    final s = value.toString();
    final dot = s.indexOf('.');
    if (dot >= 0 && s.length - dot - 1 > 4) return s.substring(0, dot + 5);
    return s;
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
