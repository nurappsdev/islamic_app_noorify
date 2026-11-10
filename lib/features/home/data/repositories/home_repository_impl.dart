import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/exceptions.dart';
import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/amol_tracking_day.dart';
import 'package:tuhfatul_muslim/features/home/data/datasources/home_remote_data_source.dart';
import 'package:tuhfatul_muslim/features/home/data/models/home_dashboard_model.dart';
import 'package:tuhfatul_muslim/features/home/domain/entities/home_dashboard.dart';
import 'package:tuhfatul_muslim/features/home/domain/repositories/home_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl(this._remote, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final HomeRemoteDataSource _remote;
  final DateTime Function() _now;

  @override
  Future<Either<Failure, HomeDashboard>> getDashboard() async {
    try {
      return Right(await _remote.getDashboard());
    } on ServerException catch (e) {
      return _fallback(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return _fallback(NetworkFailure(e.message));
    } on ParsingException catch (e) {
      return _fallback(ParsingFailure(e.message));
    } catch (_) {
      return _fallback(const UnknownFailure());
    }
  }

  /// The dashboard couldn't be fetched: fall back to the last one that was,
  /// so the cards keep showing real numbers instead of an empty/failure
  /// state. Only surfaces [failure] when nothing has ever been cached.
  ///
  /// A copy cached on an earlier day is not served at all. Its points and
  /// percentages are that day's, and showing them after midnight would carry
  /// yesterday's progress into the new day; the day itself stays recorded on
  /// the server, so nothing is lost by leaving it out here.
  Future<Either<Failure, HomeDashboard>> _fallback(Failure failure) async {
    final cachedAt = await HomeRemoteDataSourceImpl.cache.cachedAt();
    if (cachedAt == null ||
        amolTrackingDateIso(cachedAt) != amolTrackingDateIso(_now())) {
      return Left(failure);
    }
    final cached = await HomeRemoteDataSourceImpl.cache.read();
    if (cached != null) {
      try {
        return Right(HomeDashboardModel.fromJson(cached));
      } catch (_) {
        // Cached payload no longer parses (schema changed since it was
        // written) - fall through to the real failure below.
      }
    }
    return Left(failure);
  }
}
