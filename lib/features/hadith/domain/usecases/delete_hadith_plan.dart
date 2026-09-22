import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/hadith/domain/repositories/hadith_library_repository.dart';

/// Deletes one of the user's hadith plans.
class DeleteHadithPlan {
  const DeleteHadithPlan(this._repository);

  final HadithLibraryRepository _repository;

  Future<Either<Failure, Unit>> call(String id) => _repository.deletePlan(id);
}
