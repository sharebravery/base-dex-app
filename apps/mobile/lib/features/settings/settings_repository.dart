import 'package:dio/dio.dart';
import 'package:dex_app/features/settings/settings_models.dart';

abstract interface class SettingsRepository {
  Future<AppSettings> update(AppSettings settings);
}

final class ApiSettingsRepository implements SettingsRepository {
  ApiSettingsRepository(this._dio);
  final Dio _dio;

  @override
  Future<AppSettings> update(AppSettings settings) async {
    final response = await _dio.put<Map<String, Object?>>('/v1/settings', data: {
      'locale': settings.locale,
      'appearance': settings.appearance.name,
      'displayCurrency': 'USD',
      'preferBiometrics': settings.preferBiometrics,
    });
    final json = response.data!;
    return AppSettings(
      locale: json['locale']! as String,
      appearance: AppAppearance.values.byName(json['appearance']! as String),
      preferBiometrics: json['preferBiometrics']! as bool,
    );
  }
}
