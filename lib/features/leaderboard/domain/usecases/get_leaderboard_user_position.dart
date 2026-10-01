import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/leaderboard/domain/entities/leaderboard_user_detail.dart';
import 'package:tuhfatul_muslim/features/leaderboard/domain/repositories/leaderboard_repository.dart';

/// Fetches one user's standing for the Leaderboard details screen
/// (`GET /leaderboard/users/:userId?period=...&date=...`).
class GetLeaderboardUserPosition {
  const GetLeaderboardUserPosition(this._repository);

  final LeaderboardRepository _repository;

  Future<Either<Failure, LeaderboardUserDetail>> call({
    required String userId,
    required String period,
    String? date,
  }) => _repository.getUserPosition(userId: userId, period: period, date: date);
}
