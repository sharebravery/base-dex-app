import 'package:dex_app/features/settings/settings_controller.dart';
import 'package:dex_app/features/settings/settings_models.dart';
import 'package:dex_app/l10n/l10n_extension.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    required this.controller,
    required this.walletAddress,
    required this.onLogout,
    super.key,
  });

  final SettingsController controller;
  final String walletAddress;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final settings = controller.settings;
        return Scaffold(
          appBar: AppBar(title: Text(context.l10n.settings)),
          body: ListView(
            children: [
              ListTile(title: Text(context.l10n.wallet), subtitle: Text(walletAddress)),
              DropdownButtonFormField<String>(
                initialValue: settings.locale,
                items: const [
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'zh', child: Text('简体中文')),
                ],
                onChanged: (value) {
                  if (value != null) controller.update(locale: value);
                },
              ),
              DropdownButtonFormField<AppAppearance>(
                initialValue: settings.appearance,
                items: [
                  for (final value in AppAppearance.values)
                    DropdownMenuItem(
                      value: value,
                      child: Text(switch (value) {
                        AppAppearance.system => context.l10n.appearanceSystem,
                        AppAppearance.light => context.l10n.appearanceLight,
                        AppAppearance.dark => context.l10n.appearanceDark,
                      }),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) controller.update(appearance: value);
                },
              ),
              SwitchListTile(
                value: settings.preferBiometrics,
                title: Text(context.l10n.preferBiometrics),
                subtitle: Text(context.l10n.biometricsSubtitle),
                onChanged: (value) => controller.update(preferBiometrics: value),
              ),
              ListTile(
                title: Text(context.l10n.riskDisclosure),
                subtitle: Text(context.l10n.riskDisclosureBody),
              ),
              ListTile(
                title: Text(context.l10n.signOut),
                onTap: onLogout,
              ),
            ],
          ),
        );
      },
    );
  }
}
