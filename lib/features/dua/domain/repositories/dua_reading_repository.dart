import 'dart:math';

import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/failures.dart';

/// Reports dua reading to `POST /duas/reading/track` and keeps what could
/// not be sent yet, so a session read offline still counts once the server
/// is reachable again.
abstract interface class DuaReadingRepository {
  /// Whether a session is stored at all: nothing is reported for a guest.
  bool get isSignedIn;

  /// Sends [seconds] spent on [duaId] on [date]'s own calendar day. The
  /// report is saved on the device first and removed once the server has it,
  /// so a failure here only means "not yet".
  ///
  /// [sessionId] names the report: the same id saved by [saveReadingDraft],
  /// so a draft of this very session is replaced rather than sent twice.
  Future<Either<Failure, void>> trackReading({
    required String duaId,
    required int seconds,
    required DateTime date,
    String? sessionId,
  });

  /// Saves the session read so far, so an app closed mid-session still has
  /// it reported on its next launch. Never sends anything.
  Future<void> saveReadingDraft({
    required String sessionId,
    required String duaId,
    required int seconds,
    required DateTime date,
  });

  /// Drops the draft of [sessionId] — the session turned out too short to
  /// report, so no later launch may send it.
  Future<void> discardReadingDraft(String sessionId);

  /// Shows the session running right now in the already-open UI (the Amol
  /// cards' local projection) without saving or sending anything.
  void publishReadingProgress({
    required String sessionId,
    required String duaId,
    required int seconds,
    required DateTime date,
  });

  /// Sends everything still waiting on this device. Returns how many were
  /// accepted and how many are still waiting afterwards.
  Future<({int sent, int pending})> syncPendingReadings();
}

final _random = Random();

/// A new id for a dua reading report or session, unique across launches.
String newDuaReadingId() =>
    '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-'
    '${_random.nextInt(1 << 32).toRadixString(36)}';
