import 'package:dex_app/features/auth/auth_models.dart';
import 'package:dex_app/l10n/l10n_extension.dart';
import 'package:flutter/material.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({required this.onLogin, super.key});

  final Future<void> Function(WalletLoginMethod method) onLogin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(context.l10n.signInTitle, style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 12),
              Text(context.l10n.walletRecoverable),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => onLogin(WalletLoginMethod.apple),
                child: Text(context.l10n.continueWithApple),
              ),
              FilledButton.tonal(
                onPressed: () => onLogin(WalletLoginMethod.google),
                child: Text(context.l10n.continueWithGoogle),
              ),
              TextButton(
                onPressed: () => onLogin(WalletLoginMethod.email),
                child: Text(context.l10n.continueWithEmail),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
