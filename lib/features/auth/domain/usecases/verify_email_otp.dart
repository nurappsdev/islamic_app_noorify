import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/auth/domain/entities/verify_otp_params.dart';
import 'package:islami_app_noorify/features/auth/domain/repositories/account_repository.dart';

export 'package:islami_app_noorify/features/auth/domain/entities/verify_otp_params.dart';

/// Verifies the 6-digit e-mail OTP through the [AccountRepository].
///
/// On success returns the server's confirmation message (`Right`); on failure a
/// typed [Failure] (`Left`).
class VerifyEmailOtp {
  const VerifyEmailOtp(this._repository);

  final AccountRepository _repository;

  Future<Either<Failure, String>> call(VerifyOtpParams params) {
    final validationError = params.validate();
    if (validationError != null) {
      return Future.value(Left(ValidationFailure(validationError)));
    }
    return _repository.verifyEmailOtp(params);
  }
}
