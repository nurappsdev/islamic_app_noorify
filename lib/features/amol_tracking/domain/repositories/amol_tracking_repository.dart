import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/amol_tracking/domain/entities/amol_daily_dashboard.dart';

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
}
