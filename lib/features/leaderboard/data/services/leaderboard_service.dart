import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/leaderboard/data/datasources/leaderboard_remote_data_source.dart';
import 'package:islami_app_noorify/features/leaderboard/data/repositories/leaderboard_repository_impl.dart';
import 'package:islami_app_noorify/features/leaderboard/domain/entities/leaderboard_board.dart';
import 'package:islami_app_noorify/features/leaderboard/domain/repositories/leaderboard_repository.dart';
import 'package:islami_app_noorify/features/leaderboard/domain/usecases/get_leaderboard_top.dart';

/// Thin wrapper around [GetLeaderboardTop] for the Leaderboard screen.
class LeaderboardService {
  LeaderboardService._();

  static final LeaderboardService instance = LeaderboardService._();

  final LeaderboardRepository _repository = LeaderboardRepositoryImpl(
    LeaderboardRemoteDataSourceImpl(),
  );
  late final GetLeaderboardTop _getTop = GetLeaderboardTop(_repository);

  /// Fetches `GET /leaderboard/top?period=[period]&limit=[limit]`.
  Future<Either<Failure, LeaderboardBoard>> fetchTop({
    required String period,
    int limit = 10,
  }) => _getTop(period: period, limit: limit);
}
