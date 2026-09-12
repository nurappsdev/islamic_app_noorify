import 'package:islami_app_noorify/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:islami_app_noorify/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:islami_app_noorify/features/profile/domain/repositories/profile_repository.dart';
import 'package:islami_app_noorify/features/profile/domain/usecases/get_profile.dart';
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

  /// Pushes the last cached name (if any) into [profileNameNotifier] without
  /// hitting the network. Call as early as possible (e.g. right after
  /// splash resolves to the home route) so the UI never flashes a fallback.
  void hydrateFromCache() {
    final name = _repository.cachedProfile?.name;
    if (name != null && name.isNotEmpty) {
      profileNameNotifier.value = name;
    }
  }

  /// Fetches the fresh profile from the API, caches it in Hive, and updates
  /// [profileNameNotifier]. Safe to call fire-and-forget; failures are
  /// swallowed since the cached/fallback name is already on screen.
  Future<void> refresh() async {
    final result = await _getProfile();
    result.fold((_) {}, (profile) {
      if (profile.name.isNotEmpty) {
        profileNameNotifier.value = profile.name;
      }
    });
  }

  /// Clears the cached profile and resets the notifier (used on logout).
  Future<void> clear() async {
    await _repository.clearCache();
    profileNameNotifier.value = null;
  }
}
