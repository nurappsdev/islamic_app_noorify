import 'dart:async';

import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/exceptions.dart';
import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:tuhfatul_muslim/features/quran/data/datasources/quran_plan_remote_data_source.dart';
import 'package:tuhfatul_muslim/features/quran/data/repositories/quran_reading_repository_impl.dart';
import 'package:tuhfatul_muslim/features/quran/domain/quran_plan.dart';
import 'package:tuhfatul_muslim/features/quran/domain/repositories/quran_plan_repository.dart';

class QuranPlanRepositoryImpl implements QuranPlanRepository {
  QuranPlanRepositoryImpl(
    this._remote, {
    bool Function()? isSignedIn,
    this.cacheFor = const Duration(minutes: 2),
    DateTime Function()? now,
  }) : _isSignedIn = isSignedIn ?? (() => AuthLocalDataSourceImpl().hasToken),
       _now = now ?? DateTime.now {
    _readingTrackedSub = QuranReadingRepositoryImpl.shared.onReadingTracked
        .listen((_) => _onReadingTracked());
  }

  static final QuranPlanRepositoryImpl shared = QuranPlanRepositoryImpl(
    QuranPlanRemoteDataSourceImpl(),
  );

  final QuranPlanRemoteDataSource _remote;
  final bool Function() _isSignedIn;
  final DateTime Function() _now;
  final Duration cacheFor;

  StreamSubscription<void>? _readingTrackedSub;
  final _cache = <String, ({DateTime at, QuranPlansResponse value})>{};
  final _inFlight = <String, Future<QuranPlansResponse>>{};
  final _detailsCache = <String, ({DateTime at, QuranPlan value})>{};
  final _detailsInFlight = <String, Future<QuranPlan>>{};
  final _ayahsCache =
      <String, ({DateTime at, PaginatedQuranPlanAyahs value})>{};
  final _ayahsInFlight = <String, Future<PaginatedQuranPlanAyahs>>{};
  final _planChanged = StreamController<void>.broadcast();
  int _generation = 0;

  @override
  bool get isSignedIn {
    try {
      return _isSignedIn();
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<void> get onPlanChanged => _planChanged.stream;

  void _onReadingTracked() {
    invalidateCache();
    _planChanged.add(null);
  }

  @override
  void invalidateCache() {
    _generation++;
    _cache.clear();
    _inFlight.clear();
    _detailsCache.clear();
    _detailsInFlight.clear();
    _ayahsCache.clear();
    _ayahsInFlight.clear();
  }

  @override
  Future<Either<Failure, QuranPlan>> createPlan(
    CreateQuranPlanRequest request,
  ) async {
    final result = await _guard(() => _remote.createPlan(request));
    if (result.isRight()) {
      invalidateCache();
      _planChanged.add(null);
    }
    return result;
  }

  @override
  Future<Either<Failure, QuranPlansResponse>> getPlans({
    String? status,
    int page = 1,
    int limit = 10,
    bool forceRefresh = false,
  }) async {
    final key = '${status ?? "all"}:$page:$limit';
    if (!forceRefresh) {
      final hit = _cache[key];
      if (hit != null && _now().difference(hit.at) < cacheFor) {
        return Right(hit.value);
      }
    }

    final generation = _generation;
    final request = _inFlight[key] ??= _remote
        .getPlans(status: status, page: page, limit: limit)
        .whenComplete(() {
          if (generation == _generation) _inFlight.remove(key);
        });

    final result = await _guard(() async => await request);
    if (generation == _generation) {
      result.fold((_) {}, (response) {
        _cache[key] = (at: _now(), value: response);
      });
    }
    return result;
  }

  @override
  Future<Either<Failure, QuranPlan>> getPlanDetails(
    String planId, {
    bool forceRefresh = false,
  }) async {
    final key = planId;
    if (!forceRefresh) {
      final hit = _detailsCache[key];
      if (hit != null && _now().difference(hit.at) < cacheFor) {
        return Right(hit.value);
      }
    }

    final generation = _generation;
    final request = _detailsInFlight[key] ??= _remote
        .getPlanDetails(planId)
        .whenComplete(() {
          if (generation == _generation) _detailsInFlight.remove(key);
        });

    final result = await _guard(() async => await request);
    if (generation == _generation) {
      result.fold((_) {}, (plan) {
        _detailsCache[key] = (at: _now(), value: plan);
      });
    }
    return result;
  }

  @override
  Future<Either<Failure, QuranPlan>> updatePlan(
    String planId,
    UpdateQuranPlanRequest request,
  ) async {
    final result = await _guard(() => _remote.updatePlan(planId, request));
    if (result.isRight()) {
      invalidateCache();
      _planChanged.add(null);
    }
    return result;
  }

  @override
  Future<Either<Failure, QuranPlan>> completePlan(String planId) async {
    final result = await _guard(() => _remote.completePlan(planId));
    if (result.isRight()) {
      invalidateCache();
      _planChanged.add(null);
    }
    return result;
  }

  @override
  Future<Either<Failure, PaginatedQuranPlanAyahs>> getPlanAyahs(
    String planId, {
    String filter = 'all',
    int page = 1,
    int limit = 10,
    bool forceRefresh = false,
  }) async {
    final key = '$planId:$filter:$page:$limit';
    if (!forceRefresh) {
      final hit = _ayahsCache[key];
      if (hit != null && _now().difference(hit.at) < cacheFor) {
        return Right(hit.value);
      }
    }

    final generation = _generation;
    final request = _ayahsInFlight[key] ??= _remote
        .getPlanAyahs(planId, filter: filter, page: page, limit: limit)
        .whenComplete(() {
          if (generation == _generation) _ayahsInFlight.remove(key);
        });

    final result = await _guard(() async => await request);
    if (generation == _generation) {
      result.fold((_) {}, (response) {
        _ayahsCache[key] = (at: _now(), value: response);
      });
    }
    return result;
  }

  @override
  Future<Either<Failure, void>> deletePlan(String planId) async {
    final result = await _guard(() => _remote.deletePlan(planId));
    if (result.isRight()) {
      invalidateCache();
      _planChanged.add(null);
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

  void dispose() {
    _readingTrackedSub?.cancel();
  }
}
