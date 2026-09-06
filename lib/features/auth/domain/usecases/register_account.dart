import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/auth/domain/entities/auth_user.dart';
import 'package:islami_app_noorify/features/auth/domain/entities/register_params.dart';
import 'package:islami_app_noorify/features/auth/domain/repositories/account_repository.dart';

export 'package:islami_app_noorify/features/auth/domain/entities/register_params.dart';

/// Registers a new user account through the [AccountRepository].
class RegisterAccount {
  const RegisterAccount(this._repository);

  final AccountRepository _repository;

  Future<Either<Failure, AuthUser>> call(RegisterParams params) {
    final validationError = params.validate();
    if (validationError != null) {
      return Future.value(Left(ValidationFailure(validationError)));
    }
    return _repository.register(params);
  }
}
