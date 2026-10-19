import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/exceptions.dart';
import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/home/data/datasources/home_remote_data_source.dart';
import 'package:tuhfatul_muslim/features/home/data/models/home_dashboard_model.dart';
import 'package:tuhfatul_muslim/features/home/domain/entities/home_dashboard.dart';
import 'package:tuhfatul_muslim/features/home/domain/repositories/home_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl(this._remote);

  final HomeRemoteDataSource _remote;

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
  Future<Either<Failure, HomeDashboard>> _fallback(Failure failure) async {
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
