import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/hadith/domain/repositories/hadith_library_repository.dart';

/// Renames a plan, changes its target days, and / or its [status]
/// (`completed`, to mark it done).
class UpdateHadithPlan {
  const UpdateHadithPlan(this._repository);

  final HadithLibraryRepository _repository;

  Future<Either<Failure, Unit>> call(
    String id, {
    String? name,
    int? targetDays,
    String? status,
  }) => _repository.updatePlan(
    id,
    name: name,
    targetDays: targetDays,
    status: status,
  );
}
