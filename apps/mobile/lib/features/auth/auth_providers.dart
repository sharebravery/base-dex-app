import 'package:dex_app/features/auth/auth_controller.dart';
import 'package:dex_app/features/auth/auth_models.dart';
import 'package:dex_app/features/auth/wallet_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final walletServiceProvider = Provider<WalletService>((ref) {
  throw StateError('walletServiceProvider must be overridden at bootstrap');
});

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref.watch(walletServiceProvider));
});

final activeWalletSessionProvider = StateProvider<WalletSession?>((ref) => null);
