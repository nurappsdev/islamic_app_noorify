import 'package:tuhfatul_muslim/features/auth/domain/entities/user_entity.dart';
import 'package:tuhfatul_muslim/features/auth/domain/repositories/auth_repository.dart';

class SignInUseCase {
  const SignInUseCase(this._repository);

  final AuthRepository _repository;

  UserEntity? get currentUser => _repository.currentUser;

  Future<UserEntity> withEmail({
    required String email,
    required String password,
  }) {
    return _repository.signInWithEmail(email: email, password: password);
  }

  Future<UserEntity> withGoogle() {
    return _repository.signInWithGoogle();
  }

  Future<void> sendPasswordReset(String email) {
    return _repository.sendPasswordReset(email);
  }
}
