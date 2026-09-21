import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_last_read.dart';
import 'package:islami_app_noorify/features/hadith/domain/repositories/hadith_library_repository.dart';

/// The hadith the user read most recently, or null if none yet.
class GetHadithLastRead {
  const GetHadithLastRead(this._repository);

  final HadithLibraryRepository _repository;

  Future<Either<Failure, HadithLastRead?>> call() => _repository.getLastRead();
}
