import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/entities/amol_daily_dashboard.dart';

/// Contract for reading the Amol Tracking screen's daily checklist data.
abstract interface class AmolTrackingRepository {
  /// Fetches `GET /amol/tracker/daily?date=[date]` (`YYYY-MM-DD`). Returns
  /// [Right] with the [AmolDailyDashboard], or [Left] with a typed
  /// [Failure].
  Future<Either<Failure, AmolDailyDashboard>> getDaily({required String date});

  /// Marks one checklist item done via `POST /amol/tracker/log-item`.
  /// Returns [Right] with the day's updated [AmolDailyDashboard], or [Left]
  /// with a typed [Failure].
  Future<Either<Failure, AmolDailyDashboard>> logItem({
    required String logDate,
    required String pillarKey,
    required String itemKey,
  });

  /// Un-checks one checklist item via `DELETE /amol/tracker/delete-item`.
  /// Returns [Right] with the day's updated [AmolDailyDashboard], or [Left]
  /// with a typed [Failure].
  Future<Either<Failure, AmolDailyDashboard>> deleteItem({
    required String logDate,
    required String pillarKey,
    required String itemKey,
  });

  /// Sends the ticks made on this device that haven't reached the server yet,
  /// comparing each against the server's own state for its day first so
  /// nothing is logged twice. Never throws.
  ///
  /// [known] is a day already fetched by the caller, reused instead of
  /// fetching it again. Returns how many were sent and how many are still
  /// waiting.
  Future<({int sent, int pending})> syncPending({AmolDailyDashboard? known});
}
