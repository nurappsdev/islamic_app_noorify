import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/hadith/domain/entities/hadith_detail_page.dart';
import 'package:tuhfatul_muslim/features/hadith/domain/repositories/hadith_library_repository.dart';

class GetHadithDetails {
  const GetHadithDetails(this._repository);

  /// The search field filters loaded hadiths, so pages are large to reach
  /// matches quickly (the API allows up to 100).
  static const pageSize = 50;

  final HadithLibraryRepository _repository;

  /// [forceRefresh] goes to the API even when a stored copy exists, for a
  /// pull to refresh: hadiths added on the server since then show up.
  Future<Either<Failure, HadithDetailPage>> call({
    String? subCategoryId,
    String? bookId,
    String? categoryId,
    String? planId,
    int page = 1,
    bool forceRefresh = false,
  }) => _repository.getHadiths(
    subCategoryId: subCategoryId,
    bookId: bookId,
    categoryId: categoryId,
    planId: planId,
    page: page,
    limit: pageSize,
    forceRefresh: forceRefresh,
  );
}
