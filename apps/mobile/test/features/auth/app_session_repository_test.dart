import 'package:dex_app/core/secure_storage.dart';
import 'package:dex_app/features/auth/app_session_repository.dart';
import 'package:dex_app/features/auth/auth_models.dart';
import 'package:dex_app/features/auth/wallet_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

/// Fake wallet service that records signed messages and returns a fixed
/// signature, mirroring the [FakeWalletService] used in
/// `auth_controller_test.dart`.
final class FakeWalletService implements WalletService {
  FakeWalletService(this.address);

  final String address;
  final List<String> signedMessages = [];

  @override
  Future<WalletSession?> restoreSession() async => null;

  @override
  Future<WalletSession> login(WalletLoginMethod method) async =>
      WalletSession(address: address, email: null, displayName: null);

  @override
  Future<String> signMessage(String message) async {
    signedMessages.add(message);
    return '0xsigned';
  }

  @override
  Future<String> signTransaction(EvmTransactionRequest request) async =>
      '0xraw';

  @override
  Future<void> logout() async {}
}

/// In-memory fake of [SecureStorage] so the test never touches the platform
/// keychain (which is unavailable under `flutter test`).
final class FakeSecureStorage implements SecureStorage {
  String? jwt;

  @override
  Future<void> writeJwt(String token) async => jwt = token;

  @override
  Future<String?> readJwt() async => jwt;

  @override
  Future<void> clearJwt() async => jwt = null;
}

void main() {
  test('signIn performs SIWE flow and persists JWT', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    final adapter = DioAdapter(dio: dio);

    const walletAddress = '0x1111111111111111111111111111111111111111';
    const nonce = 'testnonce123';
    const domain = 'example.test';
    const uri = 'https://example.test/login';

    adapter.onPost('/v1/auth/challenge', (server) {
      server.reply(200, {
        'nonce': nonce,
        'expiresAt':
            DateTime.now().add(const Duration(minutes: 5)).toUtc().toIso8601String(),
        'domain': domain,
        'uri': uri,
        'chainId': 8453,
      });
    });

    adapter.onPost(
      '/v1/auth/verify',
      (server) {
        server.reply(200, {
          'token': 'jwt-xyz',
          'expiresInSeconds': 86400,
          'walletAddress': walletAddress,
        });
      },
      data: Matchers.any,
    );

    final wallet = FakeWalletService(walletAddress);
    final storage = FakeSecureStorage();
    final repository = AppSessionRepository(dio, wallet, storage);

    final session = await repository.signIn(const WalletSession(
      address: walletAddress,
      email: null,
      displayName: null,
    ));

    // JWT is returned and persisted.
    expect(session.token, 'jwt-xyz');
    expect(session.walletAddress, walletAddress);
    expect(storage.jwt, 'jwt-xyz');

    // Exactly one message was signed, and it is a valid EIP-4361 payload
    // carrying the challenge nonce, domain, and URI.
    expect(wallet.signedMessages, hasLength(1));
    final signed = wallet.signedMessages.single;
    expect(signed, contains('Nonce: $nonce'));
    expect(signed, contains(domain));
    expect(signed, contains('URI: $uri'));
    expect(signed, contains('Chain ID: 8453'));
    expect(signed, contains(walletAddress));
  });
}
