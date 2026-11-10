import 'package:tuhfatul_muslim/features/auth/domain/entities/user_entity.dart';
import 'package:tuhfatul_muslim/features/auth/domain/repositories/auth_repository.dart';

class SignUpUseCase {
  const SignUpUseCase(this._repository);

  final AuthRepository _repository;

  Future<UserEntity> withEmail({
    required String email,
    required String password,
  }) {
    return _repository.signUpWithEmail(email: email, password: password);
  }

  Future<UserEntity> withGoogle() {
    return _repository.signInWithGoogle();
  }
}
