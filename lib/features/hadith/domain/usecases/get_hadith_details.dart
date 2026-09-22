import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_detail_page.dart';
import 'package:islami_app_noorify/features/hadith/domain/repositories/hadith_library_repository.dart';

class GetHadithDetails {
  const GetHadithDetails(this._repository);

  /// The search field filters loaded hadiths, so pages are large to reach
  /// matches quickly (the API allows up to 100).
  static const pageSize = 50;

  final HadithLibraryRepository _repository;

  Future<Either<Failure, HadithDetailPage>> call({
    String? subCategoryId,
    String? bookId,
    String? categoryId,
    String? planId,
    int page = 1,
  }) => _repository.getHadiths(
    subCategoryId: subCategoryId,
    bookId: bookId,
    categoryId: categoryId,
    planId: planId,
    page: page,
    limit: pageSize,
  );
}
