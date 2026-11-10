import 'dart:math';

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
  ///
  /// The report is kept on the device until the server accepts it, so one
  /// made offline is sent later by [syncPendingReadings]. [sessionId] names
  /// the reading session (unique, never reused), replacing its draft from
  /// [saveReadingDraft].
  Future<Either<Failure, QuranReadingTrackResult>> trackReading({
    required int surahNumber,
    required int fromAyah,
    required int toAyah,
    required int seconds,
    required DateTime date,
    String? sessionId,
  });

  /// Keeps the session [sessionId] read so far on the device, replacing its
  /// previous draft, so it is not lost if the app is closed before
  /// [trackReading] reports it. A draft left by an earlier launch is sent by
  /// [syncPendingReadings]. Never throws.
  Future<void> saveReadingDraft({
    required String sessionId,
    required int surahNumber,
    required int fromAyah,
    required int toAyah,
    required int seconds,
    required DateTime date,
  });

  /// Drops the draft of [sessionId], a session that will not be reported.
  Future<void> discardReadingDraft(String sessionId);

  /// Sends the reports kept on the device, oldest first, one at a time;
  /// stops at the first one the network fails. Concurrent calls share one
  /// run. Never throws.
  Future<({int sent, int pending})> syncPendingReadings();

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

/// Optional live-projection capability for the Quran reader.
///
/// It never sends anything and never replaces [saveReadingDraft]'s durable
/// queue. Implementations use it only to let already-open UI show the active
/// session between local draft saves.
abstract interface class QuranReadingProgressPublisher {
  void publishReadingProgress({
    required String sessionId,
    required int surahNumber,
    required int fromAyah,
    required int toAyah,
    required int seconds,
    required DateTime date,
  });
}

final _random = Random();

/// A new id for a reading report or session, unique across launches.
String newQuranReadingId() =>
    '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-'
    '${_random.nextInt(1 << 32).toRadixString(36)}';
