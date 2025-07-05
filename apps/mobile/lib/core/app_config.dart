enum AppEnvironment { mock, staging, production }

final class AppConfig {
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.baseRpcUrl,
    required this.web3AuthClientId,
  });

  factory AppConfig.fromEnvironment() => AppConfig.fromValues(
        environment: const String.fromEnvironment(
          'APP_ENV',
          defaultValue: 'mock',
        ),
        apiBaseUrl: const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'http://127.0.0.1:8787',
        ),
        baseRpcUrl: const String.fromEnvironment(
          'BASE_RPC_URL',
          defaultValue: 'https://mainnet.base.org',
        ),
        web3AuthClientId: const String.fromEnvironment(
          'WEB3AUTH_CLIENT_ID',
          defaultValue: 'mock-client',
        ),
      );

  factory AppConfig.fromValues({
    required String environment,
    required String apiBaseUrl,
    required String baseRpcUrl,
    required String web3AuthClientId,
  }) {
    final parsedEnvironment = AppEnvironment.values.where(
      (value) => value.name == environment,
    );
    if (parsedEnvironment.length != 1) {
      throw ArgumentError.value(environment, 'environment');
    }

    final apiUri = Uri.tryParse(apiBaseUrl);
    final rpcUri = Uri.tryParse(baseRpcUrl);
    if (apiUri == null || !apiUri.hasScheme) {
      throw ArgumentError.value(apiBaseUrl, 'apiBaseUrl');
    }
    if (rpcUri == null || !rpcUri.hasScheme) {
      throw ArgumentError.value(baseRpcUrl, 'baseRpcUrl');
    }
    if (web3AuthClientId.trim().isEmpty) {
      throw ArgumentError.value(web3AuthClientId, 'web3AuthClientId');
    }

    return AppConfig(
      environment: parsedEnvironment.single,
      apiBaseUrl: apiUri,
      baseRpcUrl: rpcUri,
      web3AuthClientId: web3AuthClientId,
    );
  }

  final AppEnvironment environment;
  final Uri apiBaseUrl;
  final Uri baseRpcUrl;
  final String web3AuthClientId;
}
