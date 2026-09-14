import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/profile/domain/entities/profile_entity.dart';

/// Contract for reading the signed-in user's profile.
abstract interface class ProfileRepository {
  /// Fetches the profile from `GET /user/me` and caches it locally on
  /// success. Returns [Right] with the [ProfileEntity], or [Left] with a
  /// typed [Failure].
  Future<Either<Failure, ProfileEntity>> getMe();

  /// The last cached profile (read from Hive, no network call), or `null`
  /// when nothing has been fetched yet.
  ProfileEntity? get cachedProfile;

  /// PATCHes only the provided fields to `PATCH /user/me`, caches the
  /// server's returned profile locally on success, and returns it. All
  /// parameters are optional — omitted ones are left unchanged server-side.
  Future<Either<Failure, ProfileEntity>> updateMe({
    String? name,
    String? phone,
    String? gender,
    String? dateOfBirth,
    String? profession,
    String? location,
    String? preferredLanguage,
    String? avatarUrl,
  });

  /// Removes the cached profile (used on logout).
  Future<void> clearCache();
}
