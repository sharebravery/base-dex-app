import 'package:dex_app/features/settings/settings_models.dart';
import 'package:dex_app/features/settings/settings_repository.dart';
import 'package:flutter/foundation.dart';

final class SettingsController extends ChangeNotifier {
  SettingsController(this._repository, this._settings);
  final SettingsRepository _repository;
  AppSettings _settings;

  AppSettings get settings => _settings;

  Future<void> update({
    String? locale,
    AppAppearance? appearance,
    bool? preferBiometrics,
  }) async {
    final next = AppSettings(
      locale: locale ?? _settings.locale,
      appearance: appearance ?? _settings.appearance,
      preferBiometrics: preferBiometrics ?? _settings.preferBiometrics,
    );
    _settings = await _repository.update(next);
    notifyListeners();
  }

  bool get deviceAuthenticationRequiredForHighRiskActions => true;
}
