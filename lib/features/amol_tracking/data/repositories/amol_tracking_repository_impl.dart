import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/exceptions.dart';
import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/data/amol_pending_actions_store.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/data/datasources/amol_tracking_remote_data_source.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/data/models/amol_daily_dashboard_model.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/entities/amol_daily_dashboard.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/repositories/amol_tracking_repository.dart';

class AmolTrackingRepositoryImpl implements AmolTrackingRepository {
  AmolTrackingRepositoryImpl(this._remote, {AmolPendingActionsStore? pending})
    : _pending = pending ?? AmolPendingActionsStore();

  final AmolTrackingRemoteDataSource _remote;
  final AmolPendingActionsStore _pending;

  /// Guards re-entrant flushes (a flush itself calls `getDaily` indirectly
  /// through nothing, but two callers racing `getDaily` must not both flush
  /// the same queue at once).
  bool _flushing = false;

  @override
  Future<Either<Failure, AmolDailyDashboard>> getDaily({
    required String date,
  }) async {
    try {
      final dashboard = await _remote.getDaily(date: date);
      // Connectivity just proved itself: replay anything queued while
      // offline before handing back this snapshot, so the cards never show
      // "done" locally while the server still thinks otherwise.
      if (await _pending.hasPending) {
        await _flushPending();
        try {
          return Right(await _remote.getDaily(date: date));
        } catch (_) {
          return Right(dashboard);
        }
      }
      return Right(dashboard);
    } on ServerException catch (e) {
      return _fallback(
        ServerFailure(e.message, statusCode: e.statusCode),
        requestedDate: date,
      );
    } on NetworkException catch (e) {
      return _fallback(NetworkFailure(e.message), requestedDate: date);
    } on ParsingException catch (e) {
      return _fallback(ParsingFailure(e.message), requestedDate: date);
    } catch (_) {
      return _fallback(const UnknownFailure(), requestedDate: date);
    }
  }

  @override
  Future<Either<Failure, AmolDailyDashboard>> logItem({
    required String logDate,
    required String pillarKey,
    required String itemKey,
  }) {
    return _logOrDelete(
      isLog: true,
      logDate: logDate,
      pillarKey: pillarKey,
      itemKey: itemKey,
      action: () => _remote.logItem(
        logDate: logDate,
        pillarKey: pillarKey,
        itemKey: itemKey,
      ),
    );
  }

  @override
  Future<Either<Failure, AmolDailyDashboard>> deleteItem({
    required String logDate,
    required String pillarKey,
    required String itemKey,
  }) {
    return _logOrDelete(
      isLog: false,
      logDate: logDate,
      pillarKey: pillarKey,
      itemKey: itemKey,
      action: () => _remote.deleteItem(
        logDate: logDate,
        pillarKey: pillarKey,
        itemKey: itemKey,
      ),
    );
  }

  /// Runs a `log-item`/`delete-item` call. A connectivity failure queues the
  /// change for [_flushPending] instead of just bubbling up a [Failure] with
  /// nothing to show for it — the caller still sees [NetworkFailure] (the
  /// request plainly didn't reach the server yet), but the change itself is
  /// not lost.
  Future<Either<Failure, AmolDailyDashboard>> _logOrDelete({
    required bool isLog,
    required String logDate,
    required String pillarKey,
    required String itemKey,
    required Future<AmolDailyDashboard> Function() action,
  }) async {
    try {
      return Right(await action());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      await _pending.enqueue(
        PendingAmolAction(
          isLog: isLog,
          logDate: logDate,
          pillarKey: pillarKey,
          itemKey: itemKey,
        ),
      );
      return Left(NetworkFailure(e.message));
    } on ParsingException catch (e) {
      return Left(ParsingFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  /// Replays every queued action against the server, in the order they were
  /// made, stopping at the first one that still fails (left offline, or a
  /// real server rejection) so it — and anything after it — stays queued for
  /// the next successful [getDaily].
  Future<void> _flushPending() async {
    if (_flushing) return;
    _flushing = true;
    try {
      for (final action in await _pending.load()) {
        try {
          if (action.isLog) {
            await _remote.logItem(
              logDate: action.logDate,
              pillarKey: action.pillarKey,
              itemKey: action.itemKey,
            );
          } else {
            await _remote.deleteItem(
              logDate: action.logDate,
              pillarKey: action.pillarKey,
              itemKey: action.itemKey,
            );
          }
          await _pending.remove(action);
        } catch (_) {
          break;
        }
      }
    } finally {
      _flushing = false;
    }
  }

  /// [getDaily] couldn't be fetched: fall back to the last checklist that
  /// was, so the tracker keeps showing real progress instead of an
  /// empty/failure state. Only surfaces [failure] when nothing has ever been
  /// cached.
  Future<Either<Failure, AmolDailyDashboard>> _fallback(
    Failure failure, {
    required String requestedDate,
  }) async {
    final cached = await AmolTrackingRemoteDataSourceImpl.cache.read();
    if (cached != null) {
      try {
        final dashboard = AmolDailyDashboardModel.fromJson(cached);
        // Offline data for yesterday must never masquerade as a fresh daily
        // checklist after midnight.
        if (dashboard.dateIso == requestedDate) return Right(dashboard);
      } catch (_) {
        // Cached payload no longer parses - fall through to the real failure.
      }
    }
    return Left(failure);
  }
}
