enum AppAppearance { system, light, dark }

final class AppSettings {
  const AppSettings({
    required this.locale,
    required this.appearance,
    required this.preferBiometrics,
  });
  final String locale;
  final AppAppearance appearance;
  final bool preferBiometrics;
}
