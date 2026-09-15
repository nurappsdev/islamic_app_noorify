import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/exceptions.dart';
import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/alarm/data/datasources/alarm_local_data_source.dart';
import 'package:islami_app_noorify/features/alarm/data/datasources/alarm_remote_data_source.dart';
import 'package:islami_app_noorify/features/alarm/data/models/alarm_model.dart';
import 'package:islami_app_noorify/features/alarm/domain/entities/alarm_entry.dart';
import 'package:islami_app_noorify/features/alarm/domain/entities/ringtone.dart';
import 'package:islami_app_noorify/features/alarm/domain/repositories/alarm_repository.dart';

class AlarmRepositoryImpl implements AlarmRepository {
  AlarmRepositoryImpl(this._remote, this._local);

  final AlarmRemoteDataSource _remote;
  final AlarmLocalDataSource _local;

  @override
  Future<Either<Failure, List<AlarmEntry>>> getAlarms() async {
    try {
      return Right(await _local.getAlarms());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  /// Saves [alarm] via `POST /alarms/custom`, then caches it in the local
  /// list (used by [getAlarms]/[setAlarmEnabled]) only once the server call
  /// succeeds — a failed POST never shows a "saved" alarm that isn't.
  @override
  Future<Either<Failure, AlarmEntry>> addAlarm(AlarmEntry alarm) async {
    try {
      await _remote.createAlarm(alarm);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
    try {
      return Right(await _local.addAlarm(AlarmModel.fromEntity(alarm)));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, List<Ringtone>>> getRingtones() async {
    try {
      return Right(await _remote.getRingtones());
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

  @override
  Future<Either<Failure, void>> setAlarmEnabled({
    required String id,
    required bool enabled,
  }) async {
    try {
      await _local.setAlarmEnabled(id: id, enabled: enabled);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
