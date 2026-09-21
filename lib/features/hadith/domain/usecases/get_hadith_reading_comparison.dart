import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_reading_comparison.dart';
import 'package:islami_app_noorify/features/hadith/domain/repositories/hadith_library_repository.dart';

/// The user's reading compared with another reader's between two dates
/// (inclusive).
class GetHadithReadingComparison {
  const GetHadithReadingComparison(this._repository);

  final HadithLibraryRepository _repository;

  Future<Either<Failure, HadithReadingComparison>> call({
    required DateTime from,
    required DateTime to,
  }) => _repository.getReadingComparison(from: _format(from), to: _format(to));

  static String _format(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
