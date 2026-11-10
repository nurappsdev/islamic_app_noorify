import 'dart:async';

import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/exceptions.dart';
import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:tuhfatul_muslim/features/dua/data/datasources/dua_reading_local_data_source.dart';
import 'package:tuhfatul_muslim/features/dua/data/datasources/dua_remote_data_source.dart';
import 'package:tuhfatul_muslim/features/dua/data/services/dua_offline_reading_progress_store.dart';
import 'package:tuhfatul_muslim/features/dua/domain/dua_reading_points.dart';
import 'package:tuhfatul_muslim/features/dua/domain/repositories/dua_reading_repository.dart';

/// Reports dua reading, saving every report in
/// [DuaReadingLocalDataSource] before it is sent and removing it once the
/// server has it. Reading done offline — or cut off by the app closing — is
/// sent later by [syncPendingReadings], under the date it was read.
///
/// A report is never sent twice at once, and is dropped rather than resent
/// when the server may already have it (sent, but no answer came back) or
/// will never take it (a 4xx other than 401, 408 and 429, or [maxAttempts]
/// server errors).
class DuaReadingRepositoryImpl implements DuaReadingRepository {
  DuaReadingRepositoryImpl(
    this._remote, {
    DuaReadingLocalDataSource? local,
    bool Function()? isSignedIn,
    this.maxAttempts = 5,
    String? launch,
    this.offlineProgress,
  }) : _local = local ?? DuaReadingLocalDataSourceImpl(),
       _isSignedIn = isSignedIn ?? (() => AuthLocalDataSourceImpl().hasToken),
       launch = launch ?? newDuaReadingId();

  /// The app-wide instance, shared by the reader and the background sync.
  static final DuaReadingRepositoryImpl shared = DuaReadingRepositoryImpl(
    DuaRemoteDataSourceImpl(),
    offlineProgress: DuaOfflineReadingProgressStore.shared,
  );

  final DuaRemoteDataSource _remote;
  final DuaReadingLocalDataSource _local;
  final DuaOfflineReadingProgressStore? offlineProgress;

  /// This app launch: drafts saved under another were left by a launch that
  /// never got to report them.
  final String launch;

  /// Server errors after which a report is given up.
  final int maxAttempts;

  /// Reports being sent right now.
  final _sending = <String>{};
  Future<({int sent, int pending})>? _syncing;
  final bool Function() _isSignedIn;

  @override
  bool get isSignedIn {
    try {
      return _isSignedIn();
    } catch (_) {
      // Local auth storage not ready: treat as signed out.
      return false;
    }
  }

  @override
  Future<Either<Failure, void>> trackReading({
    required String duaId,
    required int seconds,
    required DateTime date,
    String? sessionId,
  }) async {
    final reading = PendingDuaReading(
      id: sessionId ?? newDuaReadingId(),
      duaId: duaId,
      seconds: _reportable(seconds),
      date: _day(date),
      launch: launch,
    );
    if (!_sending.add(reading.id)) {
      return const Left(UnknownFailure('Already being reported.'));
    }
    try {
      await _local.save(reading);
      offlineProgress?.upsert(reading);
    } catch (_) {
      // Storage failed: still send it, it just can't wait for a retry.
    }
    final result = await _send(reading);
    // The server is reachable again: send what waited for it.
    if (result.isRight()) unawaited(syncPendingReadings());
    return result;
  }

  @override
  Future<void> saveReadingDraft({
    required String sessionId,
    required String duaId,
    required int seconds,
    required DateTime date,
  }) async {
    if (_sending.contains(sessionId) || !isSignedIn) return;
    final reading = PendingDuaReading(
      id: sessionId,
      duaId: duaId,
      seconds: _reportable(seconds),
      date: _day(date),
      draft: true,
      launch: launch,
    );
    try {
      await _local.save(reading);
      offlineProgress?.upsert(reading);
    } catch (_) {
      // Only a safety copy: the session still reports when it ends.
    }
  }

  @override
  void publishReadingProgress({
    required String sessionId,
    required String duaId,
    required int seconds,
    required DateTime date,
  }) {
    if (!isSignedIn || seconds <= 0) return;
    offlineProgress?.upsert(
      PendingDuaReading(
        id: sessionId,
        duaId: duaId,
        seconds: _reportable(seconds),
        date: _day(date),
        draft: true,
        launch: launch,
      ),
    );
  }

  @override
  Future<void> discardReadingDraft(String sessionId) async {
    if (_sending.contains(sessionId)) return;
    await _forget(sessionId);
  }

  @override
  Future<({int sent, int pending})> syncPendingReadings() =>
      _syncing ??= _sync().whenComplete(() => _syncing = null);

  Future<({int sent, int pending})> _sync() async {
    var sent = 0;
    try {
      if (!isSignedIn) return (sent: 0, pending: 0);
      for (final reading in await _local.pending()) {
        // This launch's drafts are sessions still being read.
        if (reading.draft && reading.launch == launch) continue;
        if (!_sending.add(reading.id)) continue;
        final result = await _send(reading.copyWith(draft: false));
        if (result.isRight()) {
          sent++;
        } else if (result.fold((f) => f is NetworkFailure, (_) => false)) {
          break; // Still offline: the rest would fail too.
        }
      }
      final left = await _local.pending();
      return (
        sent: sent,
        pending: left.where((r) => !r.draft || r.launch != launch).length,
      );
    } catch (_) {
      // Storage failed: try again on the next sync.
      return (sent: sent, pending: 0);
    }
  }

  /// Sends [reading] (already marked as [_sending]) and settles its saved
  /// copy: removed once delivered or hopeless, kept to retry otherwise.
  Future<Either<Failure, void>> _send(PendingDuaReading reading) async {
    try {
      await _remote.trackReading(
        duaId: reading.duaId,
        seconds: reading.seconds,
        date: reading.date,
      );
      await _forget(reading.id, acknowledged: reading);
      return const Right(null);
    } on NetworkException catch (e) {
      if (e.mayHaveArrived) {
        await _forget(reading.id, acknowledged: reading);
      }
      return Left(NetworkFailure(e.message));
    } on AuthenticationRequiredException catch (e) {
      // The session is gone or still being renewed; the report itself is
      // fine, so it waits rather than counting an attempt.
      await _keep(reading);
      return Left(ServerFailure(e.message, statusCode: 401));
    } on ServerException catch (e) {
      final status = e.statusCode;
      final retry =
          status == null ||
          status == 401 ||
          status == 408 ||
          status == 429 ||
          status >= 500;
      // A 401 waits for the session to be renewed; it is not the report's
      // fault.
      final attempts = reading.attempts + (status == 401 ? 0 : 1);
      if (!retry || attempts >= maxAttempts) {
        await _forget(reading.id);
      } else {
        await _keep(reading.copyWith(attempts: attempts));
      }
      return Left(ServerFailure(e.message, statusCode: status));
    } on ParsingException catch (e) {
      // Accepted (2xx), just answered oddly: it counted.
      await _forget(reading.id, acknowledged: reading);
      return Left(ParsingFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    } finally {
      _sending.remove(reading.id);
    }
  }

  Future<void> _keep(PendingDuaReading reading) async {
    try {
      await _local.save(reading);
      offlineProgress?.upsert(reading);
    } catch (_) {
      /* Kept as it was. */
    }
  }

  Future<void> _forget(String id, {PendingDuaReading? acknowledged}) async {
    try {
      await _local.remove(id);
      if (acknowledged == null) {
        offlineProgress?.remove(id);
      } else {
        offlineProgress?.markAcknowledged(acknowledged);
      }
    } catch (_) {
      /* Storage failed: a later send settles it. */
    }
  }

  /// Within what the API accepts, so a report is never refused for carrying
  /// more than one call may.
  static int _reportable(int seconds) {
    if (seconds < 0) return 0;
    return seconds > kDuaReadingMaxReportSeconds
        ? kDuaReadingMaxReportSeconds
        : seconds;
  }

  /// `YYYY-MM-DD` of [d]'s own calendar day.
  static String _day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
