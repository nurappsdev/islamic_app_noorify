import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_plan.dart';
import 'package:islami_app_noorify/features/hadith/domain/repositories/hadith_library_repository.dart';

/// One page of the logged-in user's hadith plans.
class GetHadithPlans {
  const GetHadithPlans(this._repository);

  /// Matches the API's default page size.
  static const pageSize = 10;

  final HadithLibraryRepository _repository;

  /// [status] filters by `in_progress`, `completed` or `abandoned`; all plans
  /// when null.
  Future<Either<Failure, HadithPlanPage>> call({
    String? status,
    int page = 1,
  }) => _repository.getPlans(status: status, page: page, limit: pageSize);
}
