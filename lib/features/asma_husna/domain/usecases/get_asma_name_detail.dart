import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/asma_husna/domain/entities/asma_name_detail.dart';
import 'package:islami_app_noorify/features/asma_husna/domain/repositories/asma_husna_repository.dart';

/// Fetches the full explanation for one name (`GET /asma-ul-husna/{id}`).
class GetAsmaNameDetail {
  const GetAsmaNameDetail(this._repository);

  final AsmaHusnaRepository _repository;

  Future<Either<Failure, AsmaNameDetail>> call(String id) =>
      _repository.getNameDetail(id);
}
