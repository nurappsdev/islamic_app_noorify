import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_detail_page.dart';
import 'package:islami_app_noorify/features/hadith/domain/repositories/hadith_library_repository.dart';

class GetHadithDetails {
  const GetHadithDetails(this._repository);

  /// Matches the API's default page size.
  static const pageSize = 10;

  final HadithLibraryRepository _repository;

  Future<Either<Failure, HadithDetailPage>> call(
    String subCategoryId, {
    int page = 1,
  }) => _repository.getHadiths(subCategoryId, page: page, limit: pageSize);
}
