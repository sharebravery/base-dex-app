import 'package:dex_app/features/settings/settings_controller.dart';
import 'package:dex_app/features/settings/settings_models.dart';
import 'package:dex_app/features/settings/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeSettingsRepository implements SettingsRepository {
  AppSettings? received;

  @override
  Future<AppSettings> update(AppSettings settings) async {
    received = settings;
    return settings;
  }
}

void main() {
  const initial = AppSettings(
    locale: 'en',
    appearance: AppAppearance.system,
    preferBiometrics: true,
  );

  group('SettingsController', () {
    test('updates locale while preserving other fields and notifies listeners',
        () async {
      final repo = _FakeSettingsRepository();
      final controller = SettingsController(repo, initial);
      var notified = 0;
      controller.addListener(() => notified += 1);

      await controller.update(locale: 'zh');

      expect(controller.settings.locale, 'zh');
      expect(controller.settings.appearance, AppAppearance.system);
      expect(controller.settings.preferBiometrics, true);
      expect(repo.received?.locale, 'zh');
      expect(notified, 1);
    });

    test('partial appearance update preserves locale and preferBiometrics',
        () async {
      final repo = _FakeSettingsRepository();
      final controller = SettingsController(repo, initial);

      await controller.update(appearance: AppAppearance.dark);

      expect(controller.settings.appearance, AppAppearance.dark);
      expect(controller.settings.locale, 'en');
      expect(controller.settings.preferBiometrics, true);
    });
  });
}
