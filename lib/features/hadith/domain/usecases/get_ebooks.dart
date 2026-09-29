import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/hadith/domain/entities/ebook.dart';
import 'package:tuhfatul_muslim/features/hadith/domain/repositories/hadith_library_repository.dart';

class GetEbooks {
  const GetEbooks(this._repository);

  final HadithLibraryRepository _repository;

  Future<Either<Failure, List<Ebook>>> call() => _repository.getEbooks();
}
