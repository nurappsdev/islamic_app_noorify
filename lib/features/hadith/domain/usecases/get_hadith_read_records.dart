import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_read_record.dart';
import 'package:islami_app_noorify/features/hadith/domain/repositories/hadith_library_repository.dart';

/// One page of the hadiths the user has read, most recent first.
class GetHadithReadRecords {
  const GetHadithReadRecords(this._repository);

  final HadithLibraryRepository _repository;

  Future<Either<Failure, HadithReadRecordPage>> call({
    required int page,
    required int limit,
  }) => _repository.getReadRecords(page: page, limit: limit);
}
