import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/exceptions.dart';
import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/leaderboard/data/datasources/leaderboard_remote_data_source.dart';
import 'package:islami_app_noorify/features/leaderboard/domain/entities/leaderboard_board.dart';
import 'package:islami_app_noorify/features/leaderboard/domain/repositories/leaderboard_repository.dart';

class LeaderboardRepositoryImpl implements LeaderboardRepository {
  LeaderboardRepositoryImpl(this._remote);

  final LeaderboardRemoteDataSource _remote;

  @override
  Future<Either<Failure, LeaderboardBoard>> getTop({
    required String period,
    int limit = 10,
  }) async {
    try {
      return Right(await _remote.getTop(period: period, limit: limit));
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
