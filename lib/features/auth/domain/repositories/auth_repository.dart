import 'package:islami_app_noorify/features/auth/domain/entities/user_entity.dart';

abstract interface class AuthRepository {
  UserEntity? get currentUser;

  Future<UserEntity> signInWithEmail({
    required String email,
    required String password,
  });

  Future<UserEntity> signUpWithEmail({
    required String email,
    required String password,
  });

  Future<UserEntity> signInWithGoogle();

  Future<void> sendPasswordReset(String email);

  Future<void> signOut();
}
