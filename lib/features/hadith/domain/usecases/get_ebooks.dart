import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/ebook.dart';
import 'package:islami_app_noorify/features/hadith/domain/repositories/hadith_library_repository.dart';

class GetEbooks {
  const GetEbooks(this._repository);

  final HadithLibraryRepository _repository;

  Future<Either<Failure, List<Ebook>>> call() => _repository.getEbooks();
}
