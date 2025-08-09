/// Minimal EIP-4361 (Sign-In with Ethereum) message builder.
///
/// Produces the canonical SIWE message string ready for EIP-191 signing.
/// The `siwe` Dart package does not exist on pub.dev; this local implementation
/// mirrors the format produced by the JS `siwe` package (v3) used on the Worker
/// side so that `new SiweMessage(messageString).verify(...)` can parse it.
final class SiweMessage {
  SiweMessage({
    required this.domain,
    required this.address,
    required this.uri,
    required this.version,
    required this.chainId,
    required this.nonce,
    this.statement,
    this.issuedAt,
    this.expirationTime,
  });

  final String domain;
  final String address;
  final String uri;
  final String version;
  final int chainId;
  final String nonce;
  final String? statement;
  final String? issuedAt;
  final String? expirationTime;

  /// Builds the EIP-4361 formatted message, ready for EIP-191 signing.
  String prepareMessage() {
    final header = '$domain wants you to sign in with your Ethereum account:';
    final prefix = [header, address].join('\n');

    final suffix = <String>[
      'URI: $uri',
      'Version: $version',
      'Chain ID: $chainId',
      'Nonce: $nonce',
      'Issued At: ${issuedAt ?? DateTime.now().toUtc().toIso8601String()}',
    ];
    if (expirationTime != null) {
      suffix.add('Expiration Time: $expirationTime');
    }

    final suffixStr = suffix.join('\n');
    var full = [prefix, statement].join('\n\n');
    if (statement != null) {
      full += '\n';
    }
    return [full, suffixStr].join('\n');
  }
}
