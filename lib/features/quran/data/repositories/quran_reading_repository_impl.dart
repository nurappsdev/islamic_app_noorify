import 'dart:async';

import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/exceptions.dart';
import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:tuhfatul_muslim/features/quran/data/datasources/quran_reading_local_data_source.dart';
import 'package:tuhfatul_muslim/features/quran/data/datasources/quran_reading_remote_data_source.dart';
import 'package:tuhfatul_muslim/features/quran/data/services/quran_offline_reading_progress_store.dart';
import 'package:tuhfatul_muslim/features/quran/domain/quran_last_read.dart';
import 'package:tuhfatul_muslim/features/quran/domain/quran_reading_dashboard.dart';
import 'package:tuhfatul_muslim/features/quran/domain/quran_reading_history.dart';
import 'package:tuhfatul_muslim/features/quran/domain/quran_reading_progress.dart';
import 'package:tuhfatul_muslim/features/quran/domain/repositories/quran_reading_repository.dart';

/// Talks to [QuranReadingRemoteDataSource], turning its exceptions into
/// [Failure]s.
///
/// Reads are kept for [cacheFor] so switching tabs doesn't refetch, and
/// identical requests already on their way are shared rather than repeated.
/// A successful [trackReading] clears everything read so far (the numbers
/// changed) and announces it on [onReadingTracked].
///
/// Every report is saved in [QuranReadingLocalDataSource] before it is sent
/// and removed once the server has it, so reading done offline (or cut off
/// by the app closing) is sent later by [syncPendingReadings], under the
/// date it was read. A report is never sent twice at once, and is dropped
/// rather than resent when the server may already have it (sent, but no
/// answer) or will never take it (a 4xx other than 401, 408 and 429, or
/// [maxAttempts] server errors).
class QuranReadingRepositoryImpl
    implements QuranReadingRepository, QuranReadingProgressPublisher {
  QuranReadingRepositoryImpl(
    this._remote, {
    QuranReadingLocalDataSource? local,
    bool Function()? isSignedIn,
    this.cacheFor = const Duration(minutes: 2),
    this.maxAttempts = 5,
    DateTime Function()? now,
    String? launch,
    this.offlineProgress,
  }) : _local = local ?? QuranReadingLocalDataSourceImpl(),
       _isSignedIn = isSignedIn ?? (() => AuthLocalDataSourceImpl().hasToken),
       _now = now ?? DateTime.now,
       launch = launch ?? newQuranReadingId();

  /// The app-wide instance, shared by the reader, Home and the dashboard.
  static final QuranReadingRepositoryImpl shared = QuranReadingRepositoryImpl(
    QuranReadingRemoteDataSourceImpl(),
    offlineProgress: QuranOfflineReadingProgressStore.shared,
  );

  final QuranReadingRemoteDataSource _remote;
  final QuranReadingLocalDataSource _local;
  final QuranOfflineReadingProgressStore? offlineProgress;

  /// This app launch: drafts saved under another were left by a launch that
  /// never got to report them.
  final String launch;

  /// Server errors after which a report is given up.
  final int maxAttempts;

  /// Reports being sent right now.
  final _sending = <String>{};
  Future<({int sent, int pending})>? _syncing;
  final bool Function() _isSignedIn;
  final DateTime Function() _now;
  final Duration cacheFor;

  final _cache = <String, ({DateTime at, Object value})>{};
  final _inFlight = <String, Future<Object>>{};
  final _tracked = StreamController<void>.broadcast();

  /// Bumped whenever the cache is cleared, so a response requested before a
  /// track (and so possibly stale) is not cached after it.
  int _generation = 0;

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
  Stream<void> get onReadingTracked => _tracked.stream;

  @override
  Future<Either<Failure, QuranReadingTrackResult>> trackReading({
    required int surahNumber,
    required int fromAyah,
    required int toAyah,
    required int seconds,
    required DateTime date,
    String? sessionId,
  }) async {
    final reading = PendingQuranReading(
      id: sessionId ?? newQuranReadingId(),
      surahNumber: surahNumber,
      fromAyah: fromAyah,
      toAyah: toAyah,
      seconds: seconds,
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
    required int surahNumber,
    required int fromAyah,
    required int toAyah,
    required int seconds,
    required DateTime date,
  }) async {
    if (_sending.contains(sessionId) || !isSignedIn) return;
    final reading = PendingQuranReading(
      id: sessionId,
      surahNumber: surahNumber,
      fromAyah: fromAyah,
      toAyah: toAyah,
      seconds: seconds,
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
    required int surahNumber,
    required int fromAyah,
    required int toAyah,
    required int seconds,
    required DateTime date,
  }) {
    if (!isSignedIn || seconds <= 0) return;
    offlineProgress?.upsert(
      PendingQuranReading(
        id: sessionId,
        surahNumber: surahNumber,
        fromAyah: fromAyah,
        toAyah: toAyah,
        seconds: seconds,
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
  Future<Either<Failure, QuranReadingTrackResult>> _send(
    PendingQuranReading reading,
  ) async {
    try {
      final result = await _remote.trackReading(
        surahNumber: reading.surahNumber,
        fromAyah: reading.fromAyah,
        toAyah: reading.toAyah,
        seconds: reading.seconds,
        date: reading.date,
        requestId: reading.id,
      );
      await _forget(reading.id, acknowledged: reading);
      _generation++;
      _cache.clear();
      _inFlight.clear();
      _tracked.add(null);
      return Right(result);
    } on NetworkException catch (e) {
      if (e.mayHaveArrived) {
        await _forget(reading.id, acknowledged: reading);
      }
      return Left(NetworkFailure(e.message));
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

  Future<void> _keep(PendingQuranReading reading) async {
    try {
      await _local.save(reading);
      offlineProgress?.upsert(reading);
    } catch (_) {
      /* Kept as it was. */
    }
  }

  Future<void> _forget(String id, {PendingQuranReading? acknowledged}) async {
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

  @override
  Future<Either<Failure, QuranReadingDashboard>> getDashboard() =>
      _cached('dashboard', _remote.getDashboard);

  @override
  Future<Either<Failure, QuranReadingHistory>> getReadingHistory({
    int days = kQuranReadingHistoryDays,
    DateTime? from,
    DateTime? to,
  }) => _cached(
    'history:${_windowKey(days, from, to)}',
    () => _remote.getHistory(
      days: days,
      from: from == null ? null : _day(from),
      to: to == null ? null : _day(to),
    ),
  );

  @override
  Future<Either<Failure, QuranReadingComparison>> getReadingComparison({
    int days = kQuranReadingHistoryDays,
    DateTime? from,
    DateTime? to,
  }) => _cached(
    'compare:${_windowKey(days, from, to)}',
    () => _remote.getComparison(
      days: days,
      from: from == null ? null : _day(from),
      to: to == null ? null : _day(to),
    ),
  );

  @override
  Future<Either<Failure, QuranLastRead>> getLastRead() =>
      _cached('lastRead', _remote.getLastRead);

  /// A fresh cached value for [key], else the request already in flight for
  /// it, else a new one (cached if it succeeds).
  Future<Either<Failure, T>> _cached<T extends Object>(
    String key,
    Future<T> Function() fetch,
  ) async {
    final hit = _cache[key];
    if (hit != null && _now().difference(hit.at) < cacheFor) {
      return Right(hit.value as T);
    }
    final generation = _generation;
    final request = _inFlight[key] ??= fetch().whenComplete(() {
      if (generation == _generation) _inFlight.remove(key);
    });
    final result = await _guard(() async => await request as T);
    if (generation == _generation) {
      result.fold((_) {}, (value) => _cache[key] = (at: _now(), value: value));
    }
    return result;
  }

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Right(await run());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ParsingException catch (e) {
      return Left(ParsingFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  static String _windowKey(int days, DateTime? from, DateTime? to) =>
      '$days:${from == null ? '' : _day(from)}:${to == null ? '' : _day(to)}';

  /// `YYYY-MM-DD` of [d]'s own calendar day.
  static String _day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
