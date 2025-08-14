import 'package:decimal/decimal.dart';
import 'package:dex_app/features/portfolio/portfolio_controller.dart';
import 'package:dex_app/features/portfolio/portfolio_models.dart';
import 'package:dex_app/features/portfolio/portfolio_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final portfolioRepositoryProvider = Provider<PortfolioRepository>((ref) {
  throw StateError('portfolioRepositoryProvider must be overridden at bootstrap');
});

final portfolioControllerProvider = Provider<PortfolioController>((ref) {
  return PortfolioController(ref.watch(portfolioRepositoryProvider));
});

final ethPriceUsdProvider = Provider<Decimal>((ref) {
  throw StateError('ethPriceUsdProvider must be overridden by Market state');
});

final portfolioSnapshotProvider = FutureProvider.family<
    PortfolioSnapshot, String>((ref, address) {
  return ref.watch(portfolioControllerProvider).load(
        address,
        ref.watch(ethPriceUsdProvider),
      );
});
