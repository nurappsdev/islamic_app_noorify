import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/exceptions.dart';
import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/profile/data/datasources/profile_local_data_source.dart';
import 'package:islami_app_noorify/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:islami_app_noorify/features/profile/domain/entities/profile_entity.dart';
import 'package:islami_app_noorify/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._remote, {ProfileLocalDataSource? local})
    : _local = local ?? ProfileLocalDataSourceImpl();

  final ProfileRemoteDataSource _remote;
  final ProfileLocalDataSource _local;

  @override
  Future<Either<Failure, ProfileEntity>> getMe() async {
    try {
      final profile = await _remote.getMe();
      // Cache to Hive so the name is available offline / on next launch.
      await _local.cacheProfile(profile);
      return Right(profile);
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
  ProfileEntity? get cachedProfile => _local.getProfile();

  @override
  Future<void> clearCache() => _local.clearProfile();
}
