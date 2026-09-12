import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/profile/domain/entities/profile_entity.dart';
import 'package:islami_app_noorify/features/profile/domain/repositories/profile_repository.dart';

/// Fetches the signed-in user's profile from `GET /user/me`.
class GetProfile {
  const GetProfile(this._repository);

  final ProfileRepository _repository;

  Future<Either<Failure, ProfileEntity>> call() => _repository.getMe();
}
