import 'package:dex_app/l10n/app_localizations.dart';
import 'package:dex_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Deterministic golden harness for Phase 4 Task 13.
///
/// Pumps a [MaterialApp] with:
/// - Fixed [locale] (en or zh)
/// - [AppTheme.light] or [AppTheme.dark]
/// - MediaQuery override for size and text scaler
/// - Localizations delegates
/// - A single deterministic child
///
/// Callers must set the surface size in [setUp] with
/// `tester.binding.setSurfaceSize(size)` and reset it in [tearDown].
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
    MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          devicePixelRatio: 1,
          textScaler: TextScaler.linear(textScale),
        ),
        child: child,
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
