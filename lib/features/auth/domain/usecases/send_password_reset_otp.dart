import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/auth/domain/repositories/account_repository.dart';

/// Starts the forgot-password flow: asks the backend to e-mail a reset OTP.
class SendPasswordResetOtp {
  const SendPasswordResetOtp(this._repository);

  final AccountRepository _repository;

  Future<Either<Failure, String>> call(String email) {
    if (!_emailPattern.hasMatch(email.trim())) {
      return Future.value(
        const Left(ValidationFailure('Please enter a valid email address.')),
      );
    }
    return _repository.forgotPassword(email);
  }

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
}
