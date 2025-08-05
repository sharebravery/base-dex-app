import 'dart:typed_data';
import 'package:dex_app/features/auth/auth_models.dart';
import 'package:dex_app/features/auth/wallet_service.dart';
import 'package:convert/convert.dart';
import 'package:http/http.dart';
import 'package:wallet/wallet.dart';
import 'package:web3auth_flutter/enums.dart';
import 'package:web3auth_flutter/input.dart';
import 'package:web3auth_flutter/web3auth_flutter.dart';
import 'package:web3dart/web3dart.dart';

final class Web3AuthWalletService implements WalletService {
  Web3AuthWalletService({
    required this.clientId,
    required this.redirectUrl,
  });

  final String clientId;
  final Uri redirectUrl;

  Future<void> initialize() async {
    await Web3AuthFlutter.init(
      Web3AuthOptions(
        clientId: clientId,
        network: Network.sapphire_mainnet,
        redirectUrl: redirectUrl,
      ),
    );
    await Web3AuthFlutter.initialize();
  }

  @override
  Future<WalletSession?> restoreSession() async {
    final key = await Web3AuthFlutter.getPrivKey();
    if (key.isEmpty) return null;
    final address = EthPrivateKey.fromHex(key).address.eip55With0x;
    final user = await Web3AuthFlutter.getUserInfo();
    return WalletSession(
      address: address,
      email: user.email,
      displayName: user.name,
    );
  }

  @override
  Future<WalletSession> login(WalletLoginMethod method) async {
    final provider = switch (method) {
      WalletLoginMethod.email => Provider.email_passwordless,
      WalletLoginMethod.apple => Provider.apple,
      WalletLoginMethod.google => Provider.google,
    };
    final response = await Web3AuthFlutter.login(
      LoginParams(loginProvider: provider),
    );
    final key = response.privKey;
    if (key == null || key.isEmpty) {
      throw StateError('Web3Auth returned no signing key');
    }
    final address = EthPrivateKey.fromHex(key).address.eip55With0x;
    return WalletSession(
      address: address,
      email: response.userInfo?.email,
      displayName: response.userInfo?.name,
    );
  }

  @override
  Future<String> signMessage(String message) async {
    final key = await Web3AuthFlutter.getPrivKey();
    if (key.isEmpty) throw StateError('Wallet session is not available');
    final credentials = EthPrivateKey.fromHex(key);
    final signature = credentials.signPersonalMessageToUint8List(
      Uint8List.fromList(message.codeUnits),
    );
    return '0x${hex.encode(signature)}';
  }

  @override
  Future<String> signTransaction(EvmTransactionRequest request) async {
    if (request.chainId != 8453) throw ArgumentError('Unexpected chain ID');
    final key = await Web3AuthFlutter.getPrivKey();
    if (key.isEmpty) throw StateError('Wallet session is not available');
    final credentials = EthPrivateKey.fromHex(key);
    final client = Web3Client('http://localhost', Client());
    try {
      final raw = await client.signTransaction(
        credentials,
        Transaction(
          to: EthereumAddress.fromHex(request.to),
          data: Uint8List.fromList(hex.decode(request.data.replaceFirst('0x', ''))),
          value: EtherAmount.inWei(request.value),
          maxGas: request.gasLimit.toInt(),
          maxFeePerGas: EtherAmount.inWei(request.maxFeePerGas),
          maxPriorityFeePerGas:
              EtherAmount.inWei(request.maxPriorityFeePerGas),
          nonce: request.nonce,
        ),
        chainId: request.chainId,
      );
      return '0x${hex.encode(raw)}';
    } finally {
      client.dispose();
    }
  }

  @override
  Future<void> logout() => Web3AuthFlutter.logout();
}
