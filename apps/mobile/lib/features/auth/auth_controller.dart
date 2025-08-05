import 'package:dex_app/features/auth/auth_models.dart';
import 'package:dex_app/features/auth/wallet_service.dart';

final class AuthController {
  AuthController(this._walletService);
  final WalletService _walletService;

  WalletSession? _session;
  WalletSession? get session => _session;

  Future<WalletSession?> restore() async {
    _session = await _walletService.restoreSession();
    return _session;
  }

  Future<WalletSession> login(WalletLoginMethod method) async {
    _session = await _walletService.login(method);
    return _session!;
  }

  Future<void> logout() async {
    await _walletService.logout();
    _session = null;
  }
}
