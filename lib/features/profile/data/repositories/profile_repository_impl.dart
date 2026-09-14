import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/exceptions.dart';
import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/profile/data/datasources/profile_local_data_source.dart';
import 'package:islami_app_noorify/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:islami_app_noorify/features/profile/data/models/profile_model.dart';
import 'package:islami_app_noorify/features/profile/domain/entities/profile_entity.dart';
import 'package:islami_app_noorify/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._remote, {ProfileLocalDataSource? local})
    : _local = local ?? ProfileLocalDataSourceImpl();

  final ProfileRemoteDataSource _remote;
  final ProfileLocalDataSource _local;

  @override
  Future<Either<Failure, ProfileEntity>> getMe() {
    return _callAndCache(_remote.getMe);
  }

  @override
  ProfileEntity? get cachedProfile => _local.getProfile();

  @override
  Future<Either<Failure, ProfileEntity>> updateMe({
    String? name,
    String? phone,
    String? gender,
    String? dateOfBirth,
    String? profession,
    String? location,
    String? preferredLanguage,
    String? avatarUrl,
  }) {
    return _callAndCache(
      () => _remote.updateMe(
        name: name,
        phone: phone,
        gender: gender,
        dateOfBirth: dateOfBirth,
        profession: profession,
        location: location,
        preferredLanguage: preferredLanguage,
        avatarUrl: avatarUrl,
      ),
    );
  }

  /// Runs [call], caches the returned profile to Hive on success (so it's
  /// available offline / on next launch), and maps thrown data-layer
  /// exceptions to typed [Failure]s.
  Future<Either<Failure, ProfileEntity>> _callAndCache(
    Future<ProfileModel> Function() call,
  ) async {
    try {
      final profile = await call();
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
  Future<void> clearCache() => _local.clearProfile();
}
