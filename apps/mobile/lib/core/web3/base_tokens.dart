final class TokenInfo {
  const TokenInfo({
    required this.symbol,
    required this.name,
    required this.address,
    required this.decimals,
    required this.isNative,
  });

  final String symbol;
  final String name;
  final String address;
  final int decimals;
  final bool isNative;
}

abstract final class BaseTokens {
  static const eth = TokenInfo(
    symbol: 'ETH',
    name: 'Ether',
    address: '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE',
    decimals: 18,
    isNative: true,
  );
  static const usdc = TokenInfo(
    symbol: 'USDC',
    name: 'USD Coin',
    address: '0x833589fCD6eDb6E08f4c7C32D4f71b54bDa02913',
    decimals: 6,
    isNative: false,
  );
}
