import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/profile/domain/entities/profile_entity.dart';
import 'package:islami_app_noorify/features/profile/domain/repositories/profile_repository.dart';

/// Updates the signed-in user's profile via `PATCH /user/me`.
class UpdateProfile {
  const UpdateProfile(this._repository);

  final ProfileRepository _repository;

  Future<Either<Failure, ProfileEntity>> call(UpdateProfileParams params) =>
      _repository.updateMe(
        name: params.name,
        phone: params.phone,
        gender: params.gender,
        dateOfBirth: params.dateOfBirth,
        profession: params.profession,
        location: params.location,
        preferredLanguage: params.preferredLanguage,
        avatarUrl: params.avatarUrl,
      );
}

/// All fields are optional — only non-null ones are sent to the API.
class UpdateProfileParams {
  const UpdateProfileParams({
    this.name,
    this.phone,
    this.gender,
    this.dateOfBirth,
    this.profession,
    this.location,
    this.preferredLanguage,
    this.avatarUrl,
  });

  final String? name;
  final String? phone;
  final String? gender;
  final String? dateOfBirth;
  final String? profession;
  final String? location;
  final String? preferredLanguage;
  final String? avatarUrl;
}
