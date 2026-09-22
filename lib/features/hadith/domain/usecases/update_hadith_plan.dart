import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/hadith/domain/repositories/hadith_library_repository.dart';

/// Renames a plan and / or changes its target days.
class UpdateHadithPlan {
  const UpdateHadithPlan(this._repository);

  final HadithLibraryRepository _repository;

  Future<Either<Failure, Unit>> call(
    String id, {
    String? name,
    int? targetDays,
  }) => _repository.updatePlan(id, name: name, targetDays: targetDays);
}
