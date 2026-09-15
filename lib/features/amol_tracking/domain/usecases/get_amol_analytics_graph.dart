import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/amol_tracking/domain/entities/amol_analytics_graph.dart';
import 'package:islami_app_noorify/features/amol_tracking/domain/repositories/amol_analytics_repository.dart';

/// Fetches the Amol Dashboard screen's chart data
/// (`GET /amol/analytics/graph?date=YYYY-MM-DD&timeframe=daily|weekly|monthly`).
class GetAmolAnalyticsGraph {
  const GetAmolAnalyticsGraph(this._repository);

  final AmolAnalyticsRepository _repository;

  Future<Either<Failure, AmolAnalyticsGraph>> call({
    required String date,
    required String timeframe,
  }) => _repository.getGraph(date: date, timeframe: timeframe);
}
