import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/hadith/domain/repositories/hadith_library_repository.dart';

/// The ids of the hadiths already marked as read within a scope, so the
/// screen can show their Yes checkbox as checked from the start instead of
/// only after this device reports them itself.
class GetReadHadiths {
  const GetReadHadiths(this._repository);

  final HadithLibraryRepository _repository;

  Future<Either<Failure, Set<String>>> call({
    String? subCategoryId,
    String? bookId,
    String? planId,
  }) => _repository.getReadHadiths(
    subCategoryId: subCategoryId,
    bookId: bookId,
    planId: planId,
  );
}
