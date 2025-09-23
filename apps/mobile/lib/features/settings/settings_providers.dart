import 'package:dex_app/features/settings/settings_controller.dart';
import 'package:dex_app/features/settings/settings_models.dart';
import 'package:dex_app/features/settings/settings_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  throw StateError('settingsRepositoryProvider must be overridden at bootstrap');
});

final settingsControllerProvider =
    ChangeNotifierProvider<SettingsController>((ref) {
  return SettingsController(
    ref.watch(settingsRepositoryProvider),
    const AppSettings(
      locale: 'en',
      appearance: AppAppearance.dark,
      preferBiometrics: true,
    ),
  );
});
