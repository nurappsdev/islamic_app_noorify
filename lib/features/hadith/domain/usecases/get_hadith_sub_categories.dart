import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/hadith/domain/entities/hadith_sub_category_page.dart';
import 'package:tuhfatul_muslim/features/hadith/domain/repositories/hadith_library_repository.dart';

class GetHadithSubCategories {
  const GetHadithSubCategories(this._repository);

  /// Matches the API's default page size.
  static const pageSize = 10;

  final HadithLibraryRepository _repository;

  /// [forceRefresh] goes to the API even when a stored copy exists, for a
  /// pull to refresh: chapters added on the server since then show up.
  Future<Either<Failure, HadithSubCategoryPage>> call(
    String categoryId, {
    int page = 1,
    String? searchTerm,
    bool forceRefresh = false,
  }) => _repository.getSubCategories(
    categoryId,
    page: page,
    limit: pageSize,
    searchTerm: searchTerm,
    forceRefresh: forceRefresh,
  );
}
