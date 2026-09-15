import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/amol_tracking/domain/entities/amol_analytics_graph.dart';

/// Contract for reading the Amol Dashboard screen's chart data.
abstract interface class AmolAnalyticsRepository {
  /// Fetches `GET /amol/analytics/graph?date=[date]&timeframe=[timeframe]`
  /// (`date` is `YYYY-MM-DD`; `timeframe` is `daily`, `weekly` or
  /// `monthly`). Returns [Right] with the [AmolAnalyticsGraph], or [Left]
  /// with a typed [Failure].
  Future<Either<Failure, AmolAnalyticsGraph>> getGraph({
    required String date,
    required String timeframe,
  });
}
