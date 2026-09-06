import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/auth/domain/entities/auth_user.dart';
import 'package:islami_app_noorify/features/auth/domain/entities/register_params.dart';
import 'package:islami_app_noorify/features/auth/domain/entities/verify_otp_params.dart';

/// Contract for account related REST operations.
///
/// Kept separate from the Firebase-backed [AuthRepository] so the two auth
/// strategies can evolve independently.
abstract interface class AccountRepository {
  /// Registers a new user account.
  ///
  /// Returns [Right] with the created [AuthUser] on success, or [Left] with a
  /// typed [Failure] describing what went wrong.
  Future<Either<Failure, AuthUser>> register(RegisterParams params);

  /// Verifies the 6-digit e-mail OTP.
  ///
  /// Returns [Right] with the server confirmation message on success, or [Left]
  /// with a typed [Failure].
  Future<Either<Failure, String>> verifyEmailOtp(VerifyOtpParams params);
}
