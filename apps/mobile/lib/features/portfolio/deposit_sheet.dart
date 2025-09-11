import 'package:dex_app/l10n/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

class DepositSheet extends StatelessWidget {
  const DepositSheet({required this.address, super.key});
  final String address;

  @override
  Widget build(BuildContext context) {
    final payload = 'ethereum:$address@8453';
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.l10n.depositOnBase),
            const SizedBox(height: 16),
            QrImageView(data: payload, size: 220),
            const SizedBox(height: 16),
            SelectableText(address),
            TextButton.icon(
              onPressed: () => Clipboard.setData(ClipboardData(text: address)),
              icon: const Icon(Icons.copy),
              label: Text(context.l10n.copyAddress),
            ),
            Text(context.l10n.depositWarning),
          ],
        ),
      ),
    );
  }
}
