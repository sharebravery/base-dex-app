import 'package:dex_app/features/market/market_models.dart';
import 'package:dex_app/features/market/market_providers.dart';
import 'package:dex_app/features/market/market_repository.dart';
import 'package:dex_app/l10n/app_localizations.dart';
import 'package:dex_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FixtureMarketRepository implements MarketRepository {
  @override
  Future<List<MarketAsset>> getAssets() async => MarketAsset.fixtures;

  @override
  Future<List<Candle>> getCandles({
    required String assetId,
    required String interval,
  }) async =>
      const [];
}

/// Deterministic golden harness. Pumps a [MaterialApp] wrapped in a
/// [ProviderScope] with fixture-backed data providers so widgets that read
/// riverpod don't blow up under `flutter test`.
Future<void> pumpGolden(
  WidgetTester tester, {
  required Widget child,
  required Size size,
  required Locale locale,
  Brightness brightness = Brightness.light,
  double textScale = 1.0,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        marketRepositoryProvider
            .overrideWithValue(_FixtureMarketRepository()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: brightness == Brightness.dark
            ? AppTheme.dark()
            : AppTheme.light(),
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            devicePixelRatio: 1,
            textScaler: TextScaler.linear(textScale),
          ),
          child: child,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Standard sizes used across the golden matrix.
class GoldenSizes {
  static const phonePortrait = Size(390, 844);
  static const compactPhone = Size(320, 568);
}
