import 'package:dex_app/features/auth/auth_controller.dart';
import 'package:dex_app/features/auth/auth_models.dart';
import 'package:dex_app/features/auth/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';

final class FakeWalletService implements WalletService {
  WalletSession? restored;
  int logoutCalls = 0;

  @override
  Future<WalletSession?> restoreSession() async => restored;

  @override
  Future<WalletSession> login(WalletLoginMethod method) async =>
      const WalletSession(
        address: '0x1111111111111111111111111111111111111111',
        email: 'user@example.com',
        displayName: 'User',
      );

  @override
  Future<String> signMessage(String message) async => '0xsigned';

  @override
  Future<String> signTransaction(EvmTransactionRequest request) async =>
      '0xraw';

  @override
  Future<void> logout() async => logoutCalls++;
}

void main() {
  test('restores and logs in without exposing key material', () async {
    final service = FakeWalletService();
    final controller = AuthController(service);
    expect(await controller.restore(), isNull);

    final session = await controller.login(WalletLoginMethod.google);
    expect(session.address, startsWith('0x'));
    expect(controller.session, session);
  });
}
