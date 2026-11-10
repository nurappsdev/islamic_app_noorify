import 'dart:async';

import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/exceptions.dart';
import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/data/amol_day_snapshot_store.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/data/amol_pending_actions_store.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/data/datasources/amol_tracking_remote_data_source.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/data/models/amol_daily_dashboard_model.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/amol_local_projection.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/entities/amol_daily_dashboard.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/repositories/amol_tracking_repository.dart';

/// Offline-first Amol tracking.
///
/// Every tick is written to the device first and shown straight away, whether
/// or not the network is there. What the screen gets back is always the last
/// day the server sent with this device's unsent ticks applied on top
/// ([projectAmolDay]), so progress is the same before and after a restart,
/// and being offline is not an error state.
///
/// **Sync is a comparison, never a replay.** `POST log-item` is additive for
/// the entry pillars (logging adds an entry; deleting removes the last one),
/// and a tick whose *response* was lost is indistinguishable from one that
/// never arrived. So [syncPending] first reads the server's own state for the
/// day and sends only the items that actually still differ — an action that
/// already landed is dropped, not sent again. That makes syncing idempotent
/// without the backend needing an idempotency key, and it is why only the
/// tick-mark pillars ([amolQueueablePillarKeys]) are ever queued.
class AmolTrackingRepositoryImpl implements AmolTrackingRepository {
  AmolTrackingRepositoryImpl(
    this._remote, {
    AmolPendingActionsStore? pending,
    AmolDaySnapshotStore? snapshots,
  }) : _pending = pending ?? AmolPendingActionsStore.shared,
       _snapshots = snapshots ?? AmolDaySnapshotStore.shared;

  /// The instance the background sync uses.
  static final shared = AmolTrackingRepositoryImpl(
    AmolTrackingRemoteDataSourceImpl(),
  );

  final AmolTrackingRemoteDataSource _remote;
  final AmolPendingActionsStore _pending;
  final AmolDaySnapshotStore _snapshots;

  /// The sync in progress, so the screen, the Home store and the background
  /// sync can all ask at once and only one pass runs.
  static Future<({int sent, int pending})>? _syncing;

  @override
  Future<Either<Failure, AmolDailyDashboard>> getDaily({
    required String date,
  }) async {
    try {
      final fresh = await _remote.getDaily(date: date);
      // The network just proved itself: send anything waiting, then answer
      // with the day as the server sees it afterwards.
      if (await _pending.hasPending) {
        final result = await syncPending(known: fresh);
        if (result.sent > 0) {
          try {
            return Right(await _project(await _remote.getDaily(date: date)));
          } catch (_) {
            // The follow-up read failed; the projection below still shows
            // the right state.
          }
        }
      }
      return Right(await _project(fresh));
    } on ServerException catch (e) {
      return _localOr(ServerFailure(e.message, statusCode: e.statusCode), date);
    } on NetworkException catch (e) {
      return _localOr(NetworkFailure(e.message), date);
    } on ParsingException catch (e) {
      return _localOr(ParsingFailure(e.message), date);
    } catch (_) {
      return _localOr(const UnknownFailure(), date);
    }
  }

  @override
  Future<Either<Failure, AmolDailyDashboard>> logItem({
    required String logDate,
    required String pillarKey,
    required String itemKey,
  }) => _toggle(
    isLog: true,
    logDate: logDate,
    pillarKey: pillarKey,
    itemKey: itemKey,
  );

  @override
  Future<Either<Failure, AmolDailyDashboard>> deleteItem({
    required String logDate,
    required String pillarKey,
    required String itemKey,
  }) => _toggle(
    isLog: false,
    logDate: logDate,
    pillarKey: pillarKey,
    itemKey: itemKey,
  );

  Future<Either<Failure, AmolDailyDashboard>> _toggle({
    required bool isLog,
    required String logDate,
    required String pillarKey,
    required String itemKey,
  }) async {
    Future<AmolDailyDashboard> call() => isLog
        ? _remote.logItem(
            logDate: logDate,
            pillarKey: pillarKey,
            itemKey: itemKey,
          )
        : _remote.deleteItem(
            logDate: logDate,
            pillarKey: pillarKey,
            itemKey: itemKey,
          );

    // An entry pillar is additive server-side, so it is never queued: it has
    // to go straight to the server or not at all.
    if (!isAmolQueueable(pillarKey)) return _online(call);

    final action = PendingAmolAction(
      isLog: isLog,
      logDate: logDate,
      pillarKey: pillarKey,
      itemKey: itemKey,
      at: DateTime.now(),
    );
    // Queued before the request, not after it fails: a crash, or the app
    // being killed while the request is in flight, must not lose the tick.
    await _pending.save(action);
    try {
      final fresh = await call();
      await _pending.remove(action.id);
      return Right(await _project(fresh));
    } on NetworkException catch (e) {
      // Offline is the normal case here, not a failure: the tick stays on
      // the device, is shown as waiting, and syncs by itself later.
      final local = await _localDay(logDate);
      return local == null ? Left(NetworkFailure(e.message)) : Right(local);
    } on ServerException catch (e) {
      // The server answered and refused. Replaying that would just be
      // refused again, so it leaves the queue.
      await _pending.remove(action.id);
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on ParsingException catch (e) {
      // It may well have been applied — leave it queued and let the next
      // sync compare against the server instead of guessing.
      return Left(ParsingFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  Future<Either<Failure, AmolDailyDashboard>> _online(
    Future<AmolDailyDashboard> Function() call,
  ) async {
    try {
      return Right(await _project(await call()));
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

  @override
  Future<({int sent, int pending})> syncPending({AmolDailyDashboard? known}) {
    final running = _syncing;
    if (running != null) return running;
    late final Future<({int sent, int pending})> pass;
    pass = _syncPending(known).whenComplete(() {
      if (identical(_syncing, pass)) _syncing = null;
    });
    return _syncing = pass;
  }

  Future<({int sent, int pending})> _syncPending(
    AmolDailyDashboard? known,
  ) async {
    var sent = 0;
    try {
      for (final date in await _pending.pendingDates()) {
        // What the server itself holds for that day. Without this the sync
        // would be a blind replay, which can double-log.
        final AmolDailyDashboard server;
        try {
          server = known != null && known.dateIso == date
              ? known
              : await _remote.getDaily(date: date);
        } on NetworkException {
          // Still offline: leave everything queued, untouched.
          break;
        } catch (_) {
          // This day can't be verified right now; try the next one.
          continue;
        }

        var offline = false;
        for (final action in await _pending.load()) {
          if (action.logDate != date) continue;
          final onServer = _serverState(
            server,
            action.pillarKey,
            action.itemKey,
          );
          // Gone from the server's config, or already in the state the user
          // asked for (including a tick whose response was lost): nothing to
          // send.
          if (onServer == null || onServer == action.isLog) {
            await _pending.remove(action.id);
            continue;
          }
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
            await _pending.remove(action.id);
            sent++;
          } on NetworkException {
            offline = true;
            break;
          } catch (_) {
            // A refusal is counted, and dropped once it keeps happening, so
            // one bad action can't hold up the rest for good.
            await _pending.recordRejection(action);
          }
        }
        if (offline) break;
      }
    } catch (_) {
      // Never throw out of a background sync.
    }
    return (sent: sent, pending: (await _pending.load()).length);
  }

  static bool? _serverState(
    AmolDailyDashboard day,
    String pillarKey,
    String itemKey,
  ) {
    for (final pillar in day.pillars) {
      if (pillar.pillarKey != pillarKey) continue;
      for (final item in pillar.items) {
        if (item.itemKey == itemKey) return item.isCompleted;
      }
    }
    return null;
  }

  Future<AmolDailyDashboard> _project(AmolDailyDashboard day) async =>
      projectAmolDay(day, await _pending.load());

  /// The requested day as this device knows it: the stored checklist for that
  /// date, or a fresh one built from the most recent day, with everything
  /// still unsent applied on top. `null` when the server has never been
  /// reached on this device.
  Future<AmolDailyDashboard?> _localDay(String date) async {
    try {
      final stored = await _snapshots.read(date);
      if (stored != null) {
        return await _project(AmolDailyDashboardModel.fromJson(stored));
      }
      final latest = await _snapshots.latest();
      // Only ever built forward from a known day: an older date the device
      // has no record of stays unknown rather than being invented.
      if (latest == null || latest.dateIso.compareTo(date) >= 0) return null;
      return await _project(
        blankAmolDay(AmolDailyDashboardModel.fromJson(latest.json), date),
      );
    } catch (_) {
      // A stored payload that no longer parses is treated as absent.
      return null;
    }
  }

  /// Answers from the device when it can, and only surfaces [failure] when
  /// there is nothing local to show.
  Future<Either<Failure, AmolDailyDashboard>> _localOr(
    Failure failure,
    String date,
  ) async {
    final local = await _localDay(date);
    return local == null ? Left(failure) : Right(local);
  }
}
