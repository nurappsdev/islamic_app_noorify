import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/hadith/domain/entities/hadith_reading_progress.dart';
import 'package:tuhfatul_muslim/features/hadith/domain/repositories/hadith_library_repository.dart';

/// The user's reading progress per hadith category.
class GetHadithReadingProgress {
  const GetHadithReadingProgress(this._repository);

  final HadithLibraryRepository _repository;

  Future<Either<Failure, HadithReadingProgress>> call() =>
      _repository.getReadingProgress();
}
