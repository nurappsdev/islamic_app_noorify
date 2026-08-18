import 'package:islami_app_noorify/features/auth/data/models/user_model.dart';
import 'package:islami_app_noorify/features/auth/data/services/auth_service.dart';
import 'package:islami_app_noorify/features/auth/domain/entities/user_entity.dart';
import 'package:islami_app_noorify/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._service);

  final AuthService _service;

  @override
  UserEntity? get currentUser {
    final user = _service.currentUser;
    return user == null ? null : UserModel.fromFirebaseUser(user);
  }

  @override
  Future<UserEntity> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _service.signInWithEmail(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw StateError('Sign in completed without a user.');
    }
    return UserModel.fromFirebaseUser(user);
  }

  @override
  Future<UserEntity> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _service.signUpWithEmail(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw StateError('Sign up completed without a user.');
    }
    return UserModel.fromFirebaseUser(user);
  }

  @override
  Future<UserEntity> signInWithGoogle() async {
    final credential = await _service.signInWithGoogle();
    final user = credential.user;
    if (user == null) {
      throw StateError('Google sign in completed without a user.');
    }
    return UserModel.fromFirebaseUser(user);
  }

  @override
  Future<void> sendPasswordReset(String email) {
    return _service.sendPasswordReset(email);
  }

  @override
  Future<void> signOut() {
    return _service.signOut();
  }
}
