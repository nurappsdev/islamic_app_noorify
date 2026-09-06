import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/auth/domain/entities/reset_password_params.dart';
import 'package:islami_app_noorify/features/auth/domain/repositories/account_repository.dart';

export 'package:islami_app_noorify/features/auth/domain/entities/reset_password_params.dart';

/// Sets a new password after the forgot-password OTP has been verified.
class ResetPassword {
  const ResetPassword(this._repository);

  final AccountRepository _repository;

  Future<Either<Failure, String>> call(ResetPasswordParams params) {
    final validationError = params.validate();
    if (validationError != null) {
      return Future.value(Left(ValidationFailure(validationError)));
    }
    return _repository.resetPassword(params);
  }
}
