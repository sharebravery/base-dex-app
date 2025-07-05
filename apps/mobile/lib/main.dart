import 'package:dex_app/core/app_config.dart';
import 'package:flutter/widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.fromEnvironment();
}
