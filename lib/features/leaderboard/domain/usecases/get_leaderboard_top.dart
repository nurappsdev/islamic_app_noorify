import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/leaderboard/domain/entities/leaderboard_board.dart';
import 'package:islami_app_noorify/features/leaderboard/domain/repositories/leaderboard_repository.dart';

/// Fetches the Leaderboard screen's standings
/// (`GET /leaderboard/top?period=daily|weekly|monthly|yearly&limit=N`).
class GetLeaderboardTop {
  const GetLeaderboardTop(this._repository);

  final LeaderboardRepository _repository;

  Future<Either<Failure, LeaderboardBoard>> call({
    required String period,
    int limit = 10,
  }) => _repository.getTop(period: period, limit: limit);
}
