import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/asma_husna/domain/entities/asma_name.dart';
import 'package:tuhfatul_muslim/features/asma_husna/domain/repositories/asma_husna_repository.dart';

/// Fetches all 99 Names of Allah (`GET /asma-ul-husna`).
class GetAsmaNames {
  const GetAsmaNames(this._repository);

  final AsmaHusnaRepository _repository;

  Future<Either<Failure, List<AsmaName>>> call() => _repository.getNames();
}
