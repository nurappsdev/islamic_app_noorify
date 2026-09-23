import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/exceptions.dart';
import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/amol_tracking/data/datasources/amol_analytics_remote_data_source.dart';
import 'package:islami_app_noorify/features/amol_tracking/domain/entities/amol_analytics_graph.dart';
import 'package:islami_app_noorify/features/amol_tracking/domain/repositories/amol_analytics_repository.dart';

class AmolAnalyticsRepositoryImpl implements AmolAnalyticsRepository {
  AmolAnalyticsRepositoryImpl(this._remote);

  final AmolAnalyticsRemoteDataSource _remote;

  @override
  Future<Either<Failure, AmolAnalyticsGraph>> getGraph({
    required String startDate,
    required String endDate,
    required String timeframe,
    int? offset,
  }) async {
    try {
      return Right(
        await _remote.getGraph(
          startDate: startDate,
          endDate: endDate,
          timeframe: timeframe,
          offset: offset,
        ),
      );
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
