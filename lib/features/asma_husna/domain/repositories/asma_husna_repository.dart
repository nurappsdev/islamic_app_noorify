import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/asma_husna/domain/entities/asma_name.dart';

/// Contract for reading the 99 Names of Allah.
abstract interface class AsmaHusnaRepository {
  /// Fetches all 99 names (`GET /asma-ul-husna`), ordered by
  /// `displayOrder`. Returns [Right] with the full list, or [Left] with a
  /// typed [Failure].
  Future<Either<Failure, List<AsmaName>>> getNames();
}
