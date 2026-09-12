import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/amol_tracking/domain/entities/amol_daily_dashboard.dart';
import 'package:islami_app_noorify/features/amol_tracking/domain/repositories/amol_tracking_repository.dart';

/// Fetches the Amol Tracking screen's daily checklist
/// (`GET /amol/tracker/daily?date=YYYY-MM-DD`).
class GetAmolDaily {
  const GetAmolDaily(this._repository);

  final AmolTrackingRepository _repository;

  Future<Either<Failure, AmolDailyDashboard>> call({required String date}) =>
      _repository.getDaily(date: date);
}
