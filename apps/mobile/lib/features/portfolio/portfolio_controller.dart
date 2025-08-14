import 'package:decimal/decimal.dart';
import 'package:dex_app/features/portfolio/portfolio_models.dart';
import 'package:dex_app/features/portfolio/portfolio_repository.dart';

final class PortfolioController {
  PortfolioController(this._repository);
  final PortfolioRepository _repository;

  Future<PortfolioSnapshot> load(String address, Decimal ethPriceUsd) =>
      _repository.load(address: address, ethPriceUsd: ethPriceUsd);
}
