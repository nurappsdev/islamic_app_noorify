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

  /// Removes the cached profile (used on logout).
  Future<void> clearCache();
}
