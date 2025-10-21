import 'package:dex_app/app/app.dart';
import 'package:dex_app/core/app_config.dart';
import 'package:dex_app/core/mock/mock_bootstrap.dart';
import 'package:dex_app/features/auth/auth_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();
  final overrides = buildMockOverrides(config);
  runApp(
    ProviderScope(
      overrides: overrides,
      child: const _DemoInitializer(child: DexApp()),
    ),
  );
}

class _DemoInitializer extends ConsumerStatefulWidget {
  const _DemoInitializer({required this.child});

  final Widget child;

  @override
  ConsumerState<_DemoInitializer> createState() => _DemoInitializerState();
}

class _DemoInitializerState extends ConsumerState<_DemoInitializer> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(activeWalletSessionProvider.notifier).state = demoSession;
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
