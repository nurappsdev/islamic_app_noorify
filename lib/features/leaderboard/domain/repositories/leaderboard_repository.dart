import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/leaderboard/domain/entities/leaderboard_board.dart';

/// Contract for reading the top-N leaderboard standings.
abstract interface class LeaderboardRepository {
  /// Fetches `GET /leaderboard/top?period=[period]&limit=[limit]`
  /// (`period` is `daily`, `weekly`, `monthly` or `yearly`). Returns [Right]
  /// with the [LeaderboardBoard], or [Left] with a typed [Failure].
  Future<Either<Failure, LeaderboardBoard>> getTop({
    required String period,
    int limit,
  });
}
