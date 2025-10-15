import 'package:dex_app/core/widgets/glass_card.dart';
import 'package:dex_app/features/settings/settings_controller.dart';
import 'package:dex_app/features/settings/settings_models.dart';
import 'package:dex_app/l10n/l10n_extension.dart';
import 'package:dex_app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
      builder: (context, _) {
        final settings = controller.settings;
        final l10n = context.l10n;
        return Scaffold(
          appBar: AppBar(title: Text(l10n.settings)),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                // === Account =================================================
                _SectionLabel(l10n.settingsAccountSection),
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _Row(
                        icon: Icons.account_balance_wallet_outlined,
                        label: l10n.settingsWalletAddress,
                        trailing: _AddressButton(
                          address: walletAddress,
                          onCopied: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.settingsWalletCopied),
                              ),
                            );
                          },
                        ),
                      ),
                      const _Divider(),
                      _Row(
                        icon: Icons.logout_rounded,
                        label: l10n.signOut,
                        onTap: onLogout,
                        chevron: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // === Preferences =============================================
                _SectionLabel(l10n.settingsPreferencesSection),
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _Row(
                        icon: Icons.translate,
                        label: l10n.settingsLanguage,
                        trailing: _SegmentPicker<String>(
                          value: settings.locale,
                          options: const [
                            _Option('en', 'EN'),
                            _Option('zh', '中'),
                          ],
                          onChanged: (v) => controller.update(locale: v),
                        ),
                      ),
                      const _Divider(),
                      _Row(
                        icon: Icons.palette_outlined,
                        label: l10n.settingsAppearance,
                        trailing: _SegmentPicker<AppAppearance>(
                          value: settings.appearance,
                          options: [
                            _Option(
                              AppAppearance.system,
                              l10n.appearanceSystem,
                            ),
                            _Option(
                              AppAppearance.light,
                              l10n.appearanceLight,
                            ),
                            _Option(
                              AppAppearance.dark,
                              l10n.appearanceDark,
                            ),
                          ],
                          onChanged: (v) => controller.update(appearance: v),
                        ),
                      ),
                      const _Divider(),
                      _Row(
                        icon: Icons.fingerprint,
                        label: l10n.preferBiometrics,
                        subtitle: l10n.biometricsSubtitle,
                        trailing: Switch(
                          value: settings.preferBiometrics,
                          onChanged: (v) =>
                              controller.update(preferBiometrics: v),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // === Legal ===================================================
                _SectionLabel(l10n.settingsLegalSection),
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _Row(
                        icon: Icons.warning_amber_rounded,
                        label: l10n.riskDisclosure,
                        subtitle: l10n.riskDisclosureBody,
                      ),
                      const _Divider(),
                      _Row(
                        icon: Icons.info_outline,
                        label: l10n.settingsAbout,
                        subtitle: l10n.settingsAboutBody,
                      ),
                      const _Divider(),
                      _Row(
                        icon: Icons.tag,
                        label: l10n.settingsVersion,
                        trailing: Text(
                          '1.0.0',
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Divider(height: 1, color: AppColors.border),
      );
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.chevron = false,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool chevron;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: subtitle == null
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
          if (chevron)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppColors.textMuted,
              ),
            ),
        ],
      ),
    );
    if (onTap == null) return content;
    return InkWell(onTap: onTap, child: content);
  }
}

class _Option<T> {
  const _Option(this.value, this.label);
  final T value;
  final String label;
}

/// Small pill-style segmented picker used inline in the trailing slot.
class _SegmentPicker<T> extends StatelessWidget {
  const _SegmentPicker({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final T value;
  final List<_Option<T>> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final o in options)
            InkWell(
              onTap: () => onChanged(o.value),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: o.value == value
                      ? AppColors.accent.withValues(alpha: 0.18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  o.label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: o.value == value
                            ? AppColors.accent
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Short 0x… button that copies the full address on tap.
class _AddressButton extends StatelessWidget {
  const _AddressButton({required this.address, required this.onCopied});
  final String address;
  final VoidCallback onCopied;

  @override
  Widget build(BuildContext context) {
    final short = address.length > 12
        ? '${address.substring(0, 6)}…${address.substring(address.length - 4)}'
        : address;
    return InkWell(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: address));
        onCopied();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              short,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.copy,
              size: 12,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
