import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/amol_tracking/domain/entities/amol_analytics_graph.dart';
import 'package:islami_app_noorify/features/amol_tracking/domain/repositories/amol_analytics_repository.dart';

/// Fetches the Amol Dashboard screen's chart data
/// (`GET /amol/analytics/graph?timeframe=daily|weekly|monthly&startDate=YYYY-MM-DD&endDate=YYYY-MM-DD&offset=N`).
class GetAmolAnalyticsGraph {
  const GetAmolAnalyticsGraph(this._repository);

  final AmolAnalyticsRepository _repository;

  Future<Either<Failure, AmolAnalyticsGraph>> call({
    required String startDate,
    required String endDate,
    required String timeframe,
    int? offset,
  }) => _repository.getGraph(
    startDate: startDate,
    endDate: endDate,
    timeframe: timeframe,
    offset: offset,
  );
}
