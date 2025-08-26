import 'package:local_auth/local_auth.dart';

abstract interface class BiometricGate {
  Future<bool> authenticate(String reason);
}

final class LocalAuthBiometricGate implements BiometricGate {
  LocalAuthBiometricGate(this._localAuth);
  final LocalAuthentication _localAuth;

  @override
  Future<bool> authenticate(String reason) => _localAuth.authenticate(
        localizedReason: reason,
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
}
