import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/leaderboard/domain/entities/leaderboard_board.dart';
import 'package:islami_app_noorify/features/leaderboard/domain/entities/leaderboard_user_detail.dart';

/// Contract for reading the top-N leaderboard standings.
abstract interface class LeaderboardRepository {
  /// Fetches `GET /leaderboard/top?period=[period]&limit=[limit]`
  /// (`period` is `daily`, `weekly`, `monthly` or `yearly`). Returns [Right]
  /// with the [LeaderboardBoard], or [Left] with a typed [Failure].
  Future<Either<Failure, LeaderboardBoard>> getTop({
    required String period,
    int limit,
  });

  /// Fetches one user's standing for [period] (`daily`, `weekly`, `monthly`
  /// or `yearly`); [date] is that period's key from a [LeaderboardBoard]
  /// (`2026-09`).
  Future<Either<Failure, LeaderboardUserDetail>> getUserPosition({
    required String userId,
    required String period,
    String? date,
  });
}
