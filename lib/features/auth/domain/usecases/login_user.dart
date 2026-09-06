import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/auth/domain/entities/auth_user.dart';
import 'package:islami_app_noorify/features/auth/domain/entities/login_params.dart';
import 'package:islami_app_noorify/features/auth/domain/repositories/account_repository.dart';

export 'package:islami_app_noorify/features/auth/domain/entities/login_params.dart';

/// Signs the user in. On success the auth token is stored in Hive by the
/// repository; the [AuthUser] is returned here.
class LoginUser {
  const LoginUser(this._repository);

  final AccountRepository _repository;

  Future<Either<Failure, AuthUser>> call(LoginParams params) {
    final validationError = params.validate();
    if (validationError != null) {
      return Future.value(Left(ValidationFailure(validationError)));
    }
    return _repository.login(params);
  }
}
