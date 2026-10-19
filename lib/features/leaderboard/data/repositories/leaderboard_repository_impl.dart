import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/exceptions.dart';
import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/leaderboard/data/datasources/leaderboard_remote_data_source.dart';
import 'package:tuhfatul_muslim/features/leaderboard/data/models/leaderboard_board_model.dart';
import 'package:tuhfatul_muslim/features/leaderboard/data/models/leaderboard_user_detail_model.dart';
import 'package:tuhfatul_muslim/features/leaderboard/domain/entities/leaderboard_board.dart';
import 'package:tuhfatul_muslim/features/leaderboard/domain/entities/leaderboard_user_detail.dart';
import 'package:tuhfatul_muslim/features/leaderboard/domain/repositories/leaderboard_repository.dart';

class LeaderboardRepositoryImpl implements LeaderboardRepository {
  LeaderboardRepositoryImpl(this._remote);

  final LeaderboardRemoteDataSource _remote;

  @override
  Future<Either<Failure, LeaderboardBoard>> getTop({
    required String period,
    int limit = 10,
  }) => _guard(
    action: () => _remote.getTop(period: period, limit: limit),
    cacheKey: 'top_$period',
    fromJson: LeaderboardBoardModel.fromJson,
  );

  @override
  Future<Either<Failure, LeaderboardUserDetail>> getUserPosition({
    required String userId,
    required String period,
    String? date,
  }) => _guard(
    action: () =>
        _remote.getUserPosition(userId: userId, period: period, date: date),
    cacheKey: 'user_${userId}_$period',
    fromJson: LeaderboardUserDetailModel.fromJson,
  );

  /// Runs [action]; on failure, falls back to the last payload cached under
  /// [cacheKey] (via [fromJson]) instead of surfacing an empty/failure state,
  /// only propagating the real [Failure] when nothing has ever been cached.
  Future<Either<Failure, T>> _guard<T>({
    required Future<T> Function() action,
    required String cacheKey,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      return Right(await action());
    } on ServerException catch (e) {
      return _fallback(ServerFailure(e.message, statusCode: e.statusCode), cacheKey, fromJson);
    } on NetworkException catch (e) {
      return _fallback(NetworkFailure(e.message), cacheKey, fromJson);
    } on ParsingException catch (e) {
      return _fallback(ParsingFailure(e.message), cacheKey, fromJson);
    } catch (_) {
      return _fallback(const UnknownFailure(), cacheKey, fromJson);
    }
  }

  Future<Either<Failure, T>> _fallback<T>(
    Failure failure,
    String cacheKey,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final cached = await LeaderboardRemoteDataSourceImpl.cacheFor(
      cacheKey,
    ).read();
    if (cached != null) {
      try {
        return Right(fromJson(cached));
      } catch (_) {
        // Cached payload no longer parses - fall through to the real failure.
      }
    }
    return Left(failure);
  }
}
