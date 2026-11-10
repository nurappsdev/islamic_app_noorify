import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/auth/domain/entities/auth_user.dart';
import 'package:tuhfatul_muslim/features/auth/domain/entities/facebook_sign_in_params.dart';
import 'package:tuhfatul_muslim/features/auth/domain/repositories/account_repository.dart';

export 'package:tuhfatul_muslim/features/auth/domain/entities/facebook_sign_in_params.dart';

/// Exchanges a Facebook access token for an app session. On success the auth
/// token is stored in Hive by the repository; the [AuthUser] is returned here.
///
/// Mirrors [GoogleSignInUser] so a Facebook session, a Google session and an
/// e-mail session are indistinguishable to everything downstream.
class FacebookSignInUser {
  const FacebookSignInUser(this._repository);

  final AccountRepository _repository;

  Future<Either<Failure, AuthUser>> call(FacebookSignInParams params) {
    final validationError = params.validate();
    if (validationError != null) {
      return Future.value(Left(ValidationFailure(validationError)));
    }
    return _repository.facebookSignIn(params);
  }
}
