import 'dart:io';

import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:islami_app_noorify/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:islami_app_noorify/features/profile/domain/entities/profile_entity.dart';
import 'package:islami_app_noorify/features/profile/domain/repositories/profile_repository.dart';
import 'package:islami_app_noorify/features/profile/domain/usecases/get_profile.dart';
import 'package:islami_app_noorify/features/profile/domain/usecases/update_profile.dart';
import 'package:islami_app_noorify/features/profile/domain/usecases/upload_avatar.dart';
import 'package:islami_app_noorify/shared/services/app_globals.dart';

/// Keeps [profileNameNotifier] in sync with the REST profile
/// (`GET /user/me`), the same way [AuthService] keeps it in sync for the
/// Firebase auth path.
class ProfileService {
  ProfileService._();

  static final ProfileService instance = ProfileService._();

  final ProfileRepository _repository = ProfileRepositoryImpl(
    ProfileRemoteDataSourceImpl(),
  );
  late final GetProfile _getProfile = GetProfile(_repository);
  late final UpdateProfile _updateProfile = UpdateProfile(_repository);
  late final UploadAvatar _uploadAvatar = UploadAvatar(_repository);

  /// The last cached profile (no network call), or `null` when nothing has
  /// been fetched yet. Used to prefill the Edit Profile form instantly.
  ProfileEntity? get cachedProfile => _repository.cachedProfile;

  /// Fetches the freshest profile from the API, keeping
  /// [profileNameNotifier] / [profilePhotoUrlNotifier] in sync; falls back
  /// to the cache on failure so the caller still has something to show.
  Future<ProfileEntity?> fetchProfile() async {
    final result = await _getProfile();
    return result.fold((_) => _repository.cachedProfile, (profile) {
      _syncNotifiers(profile);
      return profile;
    });
  }

  /// Sends the edited fields from the Edit Profile screen to
  /// `PATCH /user/me`. All parameters are optional. On success, caches the
  /// server's returned profile and keeps [profileNameNotifier] /
  /// [profilePhotoUrlNotifier] in sync.
  Future<Either<Failure, ProfileEntity>> updateProfile({
    String? name,
    String? phone,
    String? gender,
    String? dateOfBirth,
    String? profession,
    String? location,
    String? preferredLanguage,
    String? avatarUrl,
  }) async {
    final result = await _updateProfile(
      UpdateProfileParams(
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
    result.fold((_) {}, _syncNotifiers);
    return result;
  }

  /// Uploads [file] to `POST /s3/upload` and returns its public URL. Does
  /// not touch the cached profile or notifiers — call [updateProfile] with
  /// the returned URL as `avatarUrl` to persist it.
  Future<Either<Failure, String>> uploadAvatar(File file) =>
      _uploadAvatar(file);

  /// Pushes the last cached profile (if any) into [profileNameNotifier] /
  /// [profilePhotoUrlNotifier] without hitting the network. Call as early as
  /// possible (e.g. right after splash resolves to the home route) so the UI
  /// never flashes a fallback.
  void hydrateFromCache() {
    final profile = _repository.cachedProfile;
    if (profile == null) return;
    _syncNotifiers(profile);
  }

  /// Fetches the fresh profile from the API, caches it in Hive, and updates
  /// [profileNameNotifier] / [profilePhotoUrlNotifier]. Safe to call
  /// fire-and-forget; failures are swallowed since the cached/fallback
  /// values are already on screen.
  Future<void> refresh() => fetchProfile();

  /// Mirrors [profile] into [profileNameNotifier] / [profilePhotoUrlNotifier].
  /// The avatar is skipped when the user has a custom local photo set via
  /// the Firebase auth path ([profilePhotoBase64Notifier]) — that one wins,
  /// same as [AuthService].
  void _syncNotifiers(ProfileEntity profile) {
    if (profile.name.isNotEmpty) {
      profileNameNotifier.value = profile.name;
    }
    final hasCustomLocalPhoto = (profilePhotoBase64Notifier.value ?? '')
        .trim()
        .isNotEmpty;
    if (hasCustomLocalPhoto) return;
    final url = (profile.avatarUrl ?? '').trim();
    profilePhotoUrlNotifier.value = url.isEmpty ? null : url;
  }

  /// Clears the cached profile and resets the notifiers (used on logout).
  Future<void> clear() async {
    await _repository.clearCache();
    profileNameNotifier.value = null;
    profilePhotoUrlNotifier.value = null;
  }
}
