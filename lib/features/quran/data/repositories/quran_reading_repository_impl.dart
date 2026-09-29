import 'dart:async';

import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/exceptions.dart';
import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:islami_app_noorify/features/quran/data/datasources/quran_reading_remote_data_source.dart';
import 'package:islami_app_noorify/features/quran/domain/quran_last_read.dart';
import 'package:islami_app_noorify/features/quran/domain/quran_reading_dashboard.dart';
import 'package:islami_app_noorify/features/quran/domain/quran_reading_history.dart';
import 'package:islami_app_noorify/features/quran/domain/quran_reading_progress.dart';
import 'package:islami_app_noorify/features/quran/domain/repositories/quran_reading_repository.dart';

/// Talks to [QuranReadingRemoteDataSource], turning its exceptions into
/// [Failure]s.
///
/// Reads are kept for [cacheFor] so switching tabs doesn't refetch, and
/// identical requests already on their way are shared rather than repeated.
/// A successful [trackReading] clears everything read so far (the numbers
/// changed) and announces it on [onReadingTracked].
class QuranReadingRepositoryImpl implements QuranReadingRepository {
  QuranReadingRepositoryImpl(
    this._remote, {
    bool Function()? isSignedIn,
    this.cacheFor = const Duration(minutes: 2),
    DateTime Function()? now,
  }) : _isSignedIn = isSignedIn ?? (() => AuthLocalDataSourceImpl().hasToken),
       _now = now ?? DateTime.now;

  /// The app-wide instance, shared by the reader, Home and the dashboard.
  static final QuranReadingRepositoryImpl shared = QuranReadingRepositoryImpl(
    QuranReadingRemoteDataSourceImpl(),
  );

  final QuranReadingRemoteDataSource _remote;
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
  }) async {
    final result = await _guard(
      () => _remote.trackReading(
        surahNumber: surahNumber,
        fromAyah: fromAyah,
        toAyah: toAyah,
        seconds: seconds,
        date: _day(date),
      ),
    );
    if (result.isRight()) {
      _generation++;
      _cache.clear();
      _inFlight.clear();
      _tracked.add(null);
    }
    return result;
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
