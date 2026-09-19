import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_category_page.dart';
import 'package:islami_app_noorify/features/hadith/domain/repositories/hadith_library_repository.dart';

class GetHadithCategories {
  const GetHadithCategories(this._repository);

  /// Matches the API's default page size.
  static const pageSize = 10;

  final HadithLibraryRepository _repository;

  Future<Either<Failure, HadithCategoryPage>> call(
    String bookId, {
    int page = 1,
    String? searchTerm,
  }) => _repository.getCategories(
    bookId,
    page: page,
    limit: pageSize,
    searchTerm: searchTerm,
  );
}
