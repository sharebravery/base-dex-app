import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('application wallet interface never exposes private-key methods', () {
    final source = File('lib/features/auth/wallet_service.dart').readAsStringSync();
    expect(source, isNot(contains('getPrivateKey')));
    expect(source, isNot(contains('privKey')));
    expect(source, contains('signMessage'));
    expect(source, contains('signTransaction'));
  });
}
