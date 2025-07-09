import 'package:dex_app/app/app.dart';
import 'package:dex_app/core/app_config.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.fromEnvironment();
  runApp(const ProviderScope(child: DexApp()));
}
