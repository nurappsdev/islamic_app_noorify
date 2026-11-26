import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/settings/domain/entities/product_item.dart';
import 'package:tuhfatul_muslim/features/settings/domain/repositories/settings_support_repository.dart';

/// Reads the published product list (`GET /settings/our-products`).
class GetOurProducts {
  const GetOurProducts(this._repository);

  final SettingsSupportRepository _repository;

  Future<Either<Failure, List<ProductItem>>> call() =>
      _repository.getOurProducts();
}
