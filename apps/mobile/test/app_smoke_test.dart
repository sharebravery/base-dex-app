import 'package:dex_app/core/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mock config parses valid compile-time values', () {
    final config = AppConfig.fromValues(
      environment: 'mock',
      apiBaseUrl: 'http://127.0.0.1:8787',
      baseRpcUrl: 'https://mainnet.base.org',
      web3AuthClientId: 'test-client',
    );

    expect(config.environment, AppEnvironment.mock);
    expect(config.apiBaseUrl.host, '127.0.0.1');
    expect(config.baseRpcUrl.host, 'mainnet.base.org');
  });
}
