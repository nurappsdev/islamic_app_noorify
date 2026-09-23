import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/amol_tracking/domain/entities/amol_analytics_graph.dart';

/// Contract for reading the Amol Dashboard screen's chart data.
abstract interface class AmolAnalyticsRepository {
  /// Fetches `GET /amol/analytics/graph?timeframe=[timeframe]&startDate=[startDate]&endDate=[endDate]&offset=[offset]`
  /// (`startDate`/`endDate` are `YYYY-MM-DD`; `timeframe` is `daily`,
  /// `weekly` or `monthly`; `offset` is omitted for `daily`). Returns
  /// [Right] with the [AmolAnalyticsGraph], or [Left] with a typed
  /// [Failure].
  Future<Either<Failure, AmolAnalyticsGraph>> getGraph({
    required String startDate,
    required String endDate,
    required String timeframe,
    int? offset,
  });
}
