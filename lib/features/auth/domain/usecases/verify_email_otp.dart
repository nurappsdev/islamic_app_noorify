import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/auth/domain/entities/otp_verification_result.dart';
import 'package:tuhfatul_muslim/features/auth/domain/entities/verify_otp_params.dart';
import 'package:tuhfatul_muslim/features/auth/domain/repositories/account_repository.dart';

export 'package:tuhfatul_muslim/features/auth/domain/entities/otp_verification_result.dart';
export 'package:tuhfatul_muslim/features/auth/domain/entities/verify_otp_params.dart';

/// Verifies the 6-digit OTP through the [AccountRepository].
///
/// One use case, two callers: sign-up email verification and the
/// forgot-password flow (which also gets an [OtpVerificationResult.resetToken]).
class VerifyEmailOtp {
  const VerifyEmailOtp(this._repository);

  final AccountRepository _repository;

  Future<Either<Failure, OtpVerificationResult>> call(VerifyOtpParams params) {
    final validationError = params.validate();
    if (validationError != null) {
      return Future.value(Left(ValidationFailure(validationError)));
    }
    return _repository.verifyEmailOtp(params);
  }
}
