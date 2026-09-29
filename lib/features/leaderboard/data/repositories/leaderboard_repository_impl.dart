import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/exceptions.dart';
import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/leaderboard/data/datasources/leaderboard_remote_data_source.dart';
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
  }) => _guard(() => _remote.getTop(period: period, limit: limit));

  @override
  Future<Either<Failure, LeaderboardUserDetail>> getUserPosition({
    required String userId,
    required String period,
    String? date,
  }) => _guard(
    () => _remote.getUserPosition(userId: userId, period: period, date: date),
  );

  /// Runs [action], mapping any data-layer exception to a typed [Failure].
  Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ParsingException catch (e) {
      return Left(ParsingFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
