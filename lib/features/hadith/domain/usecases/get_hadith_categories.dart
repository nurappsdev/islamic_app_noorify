import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/hadith/domain/entities/hadith_category_page.dart';
import 'package:tuhfatul_muslim/features/hadith/domain/repositories/hadith_library_repository.dart';

class GetHadithCategories {
  const GetHadithCategories(this._repository);

  /// Matches the API's default page size.
  static const pageSize = 10;

  final HadithLibraryRepository _repository;

  /// [forceRefresh] goes to the API even when a stored copy exists, for a
  /// pull to refresh: categories added on the server since then show up.
  Future<Either<Failure, HadithCategoryPage>> call(
    String bookId, {
    int page = 1,
    String? searchTerm,
    bool forceRefresh = false,
  }) => _repository.getCategories(
    bookId,
    page: page,
    limit: pageSize,
    searchTerm: searchTerm,
    forceRefresh: forceRefresh,
  );
}
