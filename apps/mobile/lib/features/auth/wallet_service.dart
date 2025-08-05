import 'package:dex_app/features/auth/auth_models.dart';

abstract interface class WalletService {
  Future<WalletSession?> restoreSession();
  Future<WalletSession> login(WalletLoginMethod method);
  Future<String> signMessage(String message);
  Future<String> signTransaction(EvmTransactionRequest request);
  Future<void> logout();
}
