import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_category.dart';
import 'package:islami_app_noorify/features/hadith/domain/repositories/hadith_library_repository.dart';

class GetHadithCategories {
  const GetHadithCategories(this._repository);

  final HadithLibraryRepository _repository;

  Future<Either<Failure, List<HadithCategory>>> call(String bookId) =>
      _repository.getCategories(bookId);
}
