import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/amol_tracking/domain/entities/amol_daily_dashboard.dart';
import 'package:islami_app_noorify/features/amol_tracking/domain/repositories/amol_tracking_repository.dart';

/// Un-checks one Amol checklist item (`DELETE /amol/tracker/delete-item`).
class DeleteAmolItem {
  const DeleteAmolItem(this._repository);

  final AmolTrackingRepository _repository;

  Future<Either<Failure, AmolDailyDashboard>> call({
    required String logDate,
    required String pillarKey,
    required String itemKey,
  }) => _repository.deleteItem(
    logDate: logDate,
    pillarKey: pillarKey,
    itemKey: itemKey,
  );
}
