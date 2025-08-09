import 'package:dex_app/core/secure_storage.dart';
import 'package:dex_app/core/siwe_message.dart';
import 'package:dex_app/features/auth/auth_models.dart';
import 'package:dex_app/features/auth/wallet_service.dart';
import 'package:dio/dio.dart';

final class AppSession {
  const AppSession({required this.token, required this.walletAddress});
  final String token;
  final String walletAddress;
}

final class AppSessionRepository {
  AppSessionRepository(this._dio, this._wallet, this._storage);
  final Dio _dio;
  final WalletService _wallet;
  final SecureStorage _storage;

  Future<AppSession> signIn(WalletSession walletSession) async {
    final challenge = await _dio.post<Map<String, Object?>>('/v1/auth/challenge');
    final data = challenge.data!;
    final message = SiweMessage(
      domain: data['domain']! as String,
      address: walletSession.address,
      statement: 'Sign in to Flutter DEX',
      uri: data['uri']! as String,
      version: '1',
      chainId: data['chainId']! as int,
      nonce: data['nonce']! as String,
      issuedAt: DateTime.now().toUtc().toIso8601String(),
      expirationTime: data['expiresAt']! as String,
    ).prepareMessage();
    final signature = await _wallet.signMessage(message);
    final verified = await _dio.post<Map<String, Object?>>(
      '/v1/auth/verify',
      data: {'message': message, 'signature': signature},
    );
    final token = verified.data!['token']! as String;
    await _storage.writeJwt(token);
    return AppSession(token: token, walletAddress: walletSession.address);
  }
}
