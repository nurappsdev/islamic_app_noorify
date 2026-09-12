import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/amol_tracking/domain/entities/amol_daily_dashboard.dart';

/// Contract for reading the Amol Tracking screen's daily checklist data.
abstract interface class AmolTrackingRepository {
  /// Fetches `GET /amol/tracker/daily?date=[date]` (`YYYY-MM-DD`). Returns
  /// [Right] with the [AmolDailyDashboard], or [Left] with a typed
  /// [Failure].
  Future<Either<Failure, AmolDailyDashboard>> getDaily({required String date});
}
