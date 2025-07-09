import 'package:dex_app/app/router.dart';
import 'package:dex_app/l10n/app_localizations.dart';
import 'package:dex_app/theme/app_theme.dart';
import 'package:flutter/material.dart';

class DexApp extends StatelessWidget {
  const DexApp({super.key, this.locale});

  final Locale? locale;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: appRouter,
    );
  }
}
