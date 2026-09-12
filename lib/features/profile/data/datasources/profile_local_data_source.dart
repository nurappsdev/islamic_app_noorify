import 'package:hive/hive.dart';

import 'package:islami_app_noorify/core/storage/hive_service.dart';
import 'package:islami_app_noorify/features/profile/data/models/profile_model.dart';

/// Local (Hive-backed) cache for the signed-in user's profile.
///
/// Shares the auth box with [AuthLocalDataSourceImpl] so the profile is
/// cleared automatically whenever that box is (e.g. on a full sign-out).
abstract interface class ProfileLocalDataSource {
  /// Persists the latest profile fetched from `GET /user/me`.
  Future<void> cacheProfile(ProfileModel profile);

  /// The last cached profile, or `null` when nothing has been fetched yet.
  ProfileModel? getProfile();

  /// Removes the cached profile (used on logout).
  Future<void> clearProfile();
}

class ProfileLocalDataSourceImpl implements ProfileLocalDataSource {
  ProfileLocalDataSourceImpl({Box<dynamic>? box})
    : _box = box ?? HiveService.auth;

  static const String _profileKey = 'profile_data';

  final Box<dynamic> _box;

  @override
  Future<void> cacheProfile(ProfileModel profile) =>
      _box.put(_profileKey, profile.toJson());

  @override
  ProfileModel? getProfile() {
    final value = _box.get(_profileKey);
    if (value is! Map) return null;
    try {
      return ProfileModel.fromJson(Map<String, dynamic>.from(value));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearProfile() => _box.delete(_profileKey);
}
