import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/hadith/domain/entities/hadith_library_book.dart';
import 'package:tuhfatul_muslim/features/hadith/domain/repositories/hadith_library_repository.dart';

class GetHadithLibraryBooks {
  const GetHadithLibraryBooks(this._repository);

  final HadithLibraryRepository _repository;

  Future<Either<Failure, List<HadithLibraryBook>>> call() =>
      _repository.getBooks();
}
