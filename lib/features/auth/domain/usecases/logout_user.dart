import 'package:islami_app_noorify/features/auth/domain/repositories/account_repository.dart';

/// Clears the local session — removes the auth token from Hive so the session
/// is completely cleared (used by the Sign Out button on the Profile screen).
class LogoutUser {
  const LogoutUser(this._repository);

  final AccountRepository _repository;

  Future<void> call() => _repository.logout();
}
