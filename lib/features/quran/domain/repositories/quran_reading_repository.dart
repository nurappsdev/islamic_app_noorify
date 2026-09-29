import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/quran/domain/quran_last_read.dart';
import 'package:tuhfatul_muslim/features/quran/domain/quran_reading_dashboard.dart';
import 'package:tuhfatul_muslim/features/quran/domain/quran_reading_history.dart';
import 'package:tuhfatul_muslim/features/quran/domain/quran_reading_progress.dart';

/// Default window, in days, of the reading history and comparison.
const kQuranReadingHistoryDays = 7;

/// The signed-in user's Quran reading: what they read, and their progress.
abstract interface class QuranReadingRepository {
  /// Whether a user is signed in; the reading endpoints need one.
  bool get isSignedIn;

  /// Fires after each successfully tracked reading, once the cached reading
  /// data has been cleared — screens showing it should reload.
  Stream<void> get onReadingTracked;

  /// Reports [seconds] spent reading ayahs [fromAyah]-[toAyah] of
  /// [surahNumber] on [date] (the local calendar day).
  Future<Either<Failure, QuranReadingTrackResult>> trackReading({
    required int surahNumber,
    required int fromAyah,
    required int toAyah,
    required int seconds,
    required DateTime date,
  });

  Future<Either<Failure, QuranReadingDashboard>> getDashboard();

  /// The last [days] days, or the [from]-[to] calendar window when given.
  Future<Either<Failure, QuranReadingHistory>> getReadingHistory({
    int days = kQuranReadingHistoryDays,
    DateTime? from,
    DateTime? to,
  });

  /// Same window as [getReadingHistory].
  Future<Either<Failure, QuranReadingComparison>> getReadingComparison({
    int days = kQuranReadingHistoryDays,
    DateTime? from,
    DateTime? to,
  });

  Future<Either<Failure, QuranLastRead>> getLastRead();
}
