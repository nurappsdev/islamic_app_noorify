import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_sub_category_page.dart';
import 'package:islami_app_noorify/features/hadith/domain/repositories/hadith_library_repository.dart';

class GetHadithSubCategories {
  const GetHadithSubCategories(this._repository);

  /// Matches the API's default page size.
  static const pageSize = 10;

  final HadithLibraryRepository _repository;

  Future<Either<Failure, HadithSubCategoryPage>> call(
    String categoryId, {
    int page = 1,
    String? searchTerm,
  }) => _repository.getSubCategories(
    categoryId,
    page: page,
    limit: pageSize,
    searchTerm: searchTerm,
  );
}
