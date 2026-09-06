import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/auth/domain/entities/auth_user.dart';
import 'package:islami_app_noorify/features/auth/domain/entities/login_params.dart';
import 'package:islami_app_noorify/features/auth/domain/entities/otp_verification_result.dart';
import 'package:islami_app_noorify/features/auth/domain/entities/register_params.dart';
import 'package:islami_app_noorify/features/auth/domain/entities/reset_password_params.dart';
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

  /// Verifies the 6-digit OTP (shared by the sign-up and forgot-password flows).
  ///
  /// Returns [Right] with the [OtpVerificationResult] (message + optional
  /// `resetToken`) on success, or [Left] with a typed [Failure].
  Future<Either<Failure, OtpVerificationResult>> verifyEmailOtp(
    VerifyOtpParams params,
  );

  /// Requests a fresh verification OTP for [email].
  ///
  /// Returns [Right] with the server confirmation message, or [Left] with a
  /// typed [Failure].
  Future<Either<Failure, String>> resendOtp(String email);

  /// Starts the forgot-password flow: e-mails a reset OTP to [email].
  Future<Either<Failure, String>> forgotPassword(String email);

  /// Sets a new password using the reset token from OTP verification.
  Future<Either<Failure, String>> resetPassword(ResetPasswordParams params);

  /// Signs in with email + password. On success the auth token is persisted to
  /// local storage (Hive) and the signed-in [AuthUser] is returned.
  Future<Either<Failure, AuthUser>> login(LoginParams params);

  /// Clears the persisted session (removes the token from Hive).
  Future<void> logout();

  /// The persisted auth token, or `null` when signed out.
  String? get authToken;

  /// `true` while a token is stored locally.
  bool get isSignedIn;
}
