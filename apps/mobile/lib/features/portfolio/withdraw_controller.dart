final class WithdrawController {
  const WithdrawController();

  String? validate({
    required String address,
    required String amount,
    required int decimals,
  }) {
    if (!RegExp(r'^0x[a-fA-F0-9]{40}$').hasMatch(address)) return 'invalid_address';
    final parts = amount.split('.');
    if (parts.length > 2) return 'invalid_amount';
    final whole = BigInt.tryParse(parts.first);
    if (whole == null || (parts.length == 1 && whole <= BigInt.zero)) return 'invalid_amount';
    final fraction = parts.length == 2 ? parts[1] : '';
    if (fraction.length > decimals) return 'too_many_decimals';
    if (fraction.isNotEmpty && BigInt.tryParse(fraction) == null) return 'invalid_amount';
    final raw = BigInt.parse('${parts.first}${fraction.padRight(decimals, '0')}');
    if (raw <= BigInt.zero) return 'invalid_amount';
    return null;
  }

  BigInt toRawAmount(String amount, int decimals) {
    final parts = amount.split('.');
    final fraction = parts.length == 2 ? parts[1] : '';
    return BigInt.parse('${parts.first}${fraction.padRight(decimals, '0')}');
  }
}
