import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/exceptions.dart';
import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/amol_tracking/data/datasources/amol_tracking_remote_data_source.dart';
import 'package:islami_app_noorify/features/amol_tracking/domain/entities/amol_daily_dashboard.dart';
import 'package:islami_app_noorify/features/amol_tracking/domain/repositories/amol_tracking_repository.dart';

class AmolTrackingRepositoryImpl implements AmolTrackingRepository {
  AmolTrackingRepositoryImpl(this._remote);

  final AmolTrackingRemoteDataSource _remote;

  @override
  Future<Either<Failure, AmolDailyDashboard>> getDaily({required String date}) {
    return _guard(() => _remote.getDaily(date: date));
  }

  @override
  Future<Either<Failure, AmolDailyDashboard>> logItem({
    required String logDate,
    required String pillarKey,
    required String itemKey,
  }) {
    return _guard(
      () => _remote.logItem(
        logDate: logDate,
        pillarKey: pillarKey,
        itemKey: itemKey,
      ),
    );
  }

  @override
  Future<Either<Failure, AmolDailyDashboard>> deleteItem({
    required String logDate,
    required String pillarKey,
    required String itemKey,
  }) {
    return _guard(
      () => _remote.deleteItem(
        logDate: logDate,
        pillarKey: pillarKey,
        itemKey: itemKey,
      ),
    );
  }

  /// Runs [action], mapping any data-layer exception to a typed [Failure].
  Future<Either<Failure, AmolDailyDashboard>> _guard(
    Future<AmolDailyDashboard> Function() action,
  ) async {
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
