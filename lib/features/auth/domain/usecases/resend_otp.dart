import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/auth/domain/repositories/account_repository.dart';

/// Requests a fresh verification OTP e-mail.
class ResendOtp {
  const ResendOtp(this._repository);

  final AccountRepository _repository;

  Future<Either<Failure, String>> call(String email) {
    if (!_emailPattern.hasMatch(email.trim())) {
      return Future.value(
        const Left(ValidationFailure('Please enter a valid email address.')),
      );
    }
    return _repository.resendOtp(email);
  }

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
}
