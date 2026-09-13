import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/amol_tracking/domain/entities/amol_daily_dashboard.dart';
import 'package:islami_app_noorify/features/amol_tracking/domain/repositories/amol_tracking_repository.dart';

/// Marks one Amol checklist item done (`POST /amol/tracker/log-item`).
///
/// Client-side prayer-time gating happens before this is called — see the
/// screen that dispatches it.
class LogAmolItem {
  const LogAmolItem(this._repository);

  final AmolTrackingRepository _repository;

  Future<Either<Failure, AmolDailyDashboard>> call({
    required String logDate,
    required String pillarKey,
    required String itemKey,
  }) => _repository.logItem(
    logDate: logDate,
    pillarKey: pillarKey,
    itemKey: itemKey,
  );
}
