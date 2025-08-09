import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Contract for persisting the application session JWT.
///
/// Declared as an [abstract interface class] so tests can inject an in-memory
/// fake and never touch the platform keychain (which is unavailable under
/// `flutter test`).
abstract interface class SecureStorage {
  Future<void> writeJwt(String token);
  Future<String?> readJwt();
  Future<void> clearJwt();
}

/// Production [SecureStorage] backed by [FlutterSecureStorage].
final class FlutterSecureStorageAdapter implements SecureStorage {
  FlutterSecureStorageAdapter([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _storage;

  static const _jwtKey = 'app_session_jwt';

  @override
  Future<void> writeJwt(String token) => _storage.write(key: _jwtKey, value: token);

  @override
  Future<String?> readJwt() => _storage.read(key: _jwtKey);

  @override
  Future<void> clearJwt() => _storage.delete(key: _jwtKey);
}
