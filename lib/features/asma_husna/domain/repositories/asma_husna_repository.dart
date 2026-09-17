import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/asma_husna/domain/entities/asma_name.dart';
import 'package:islami_app_noorify/features/asma_husna/domain/entities/asma_name_detail.dart';

/// Contract for reading the 99 Names of Allah. Cache-first: implementations
/// hit `GET /asma-ul-husna` only once and serve every later call from local
/// storage — see `AsmaHusnaRepositoryImpl`.
abstract interface class AsmaHusnaRepository {
  /// The 99 names, each with its full explanation, ordered by
  /// `displayOrder`. Returns [Right] with the full list, or [Left] with a
  /// typed [Failure].
  Future<Either<Failure, List<AsmaName>>> getNames();

  /// The full explanation for one name.
  Future<Either<Failure, AsmaNameDetail>> getNameDetail(String id);
}
