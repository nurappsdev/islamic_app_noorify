import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/hadith/domain/repositories/hadith_library_repository.dart';

/// Reports how long a hadith was actively read, and whether it was completed.
class TrackHadithReading {
  const TrackHadithReading(this._repository);

  final HadithLibraryRepository _repository;

  Future<Either<Failure, Unit>> call({
    required String hadithId,
    required int seconds,
    required bool completed,
    required DateTime date,
  }) => _repository.trackReading(
    hadithId: hadithId,
    seconds: seconds,
    completed: completed,
    date: _formatDate(date),
  );

  static String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
