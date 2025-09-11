import 'package:dex_app/features/portfolio/withdraw_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rejects invalid address, zero amount, and USDC precision above six', () {
    const controller = WithdrawController();
    expect(controller.validate(address: 'bad', amount: '1', decimals: 6), 'invalid_address');
    expect(controller.validate(address: '0x1111111111111111111111111111111111111111', amount: '0', decimals: 6), 'invalid_amount');
    expect(controller.validate(address: '0x1111111111111111111111111111111111111111', amount: '1.0000001', decimals: 6), 'too_many_decimals');
  });

  test('accepts a valid USDC withdrawal and computes raw base units', () {
    const controller = WithdrawController();
    expect(
      controller.validate(
        address: '0x1111111111111111111111111111111111111111',
        amount: '1.5',
        decimals: 6,
      ),
      isNull,
    );
    expect(controller.toRawAmount('1.5', 6), BigInt.parse('1500000'));
  });
}
