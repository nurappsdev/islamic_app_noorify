import 'package:flutter/material.dart';

import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/account_repository_impl.dart';
import '../../domain/usecases/send_password_reset_otp.dart';
import 'email_verification_screen.dart';
import 'reset_password_screen.dart';

/// Forgot-password flow:
/// email -> `POST /auth/forgot-password` -> OTP -> `POST /auth/verify-otp`
/// -> Reset Password screen (with the reset token from verification).
class ForgotPasswordScreen extends StatelessWidget {
  ForgotPasswordScreen({super.key})
    : _sendResetOtp = SendPasswordResetOtp(
        AccountRepositoryImpl(AuthRemoteDataSourceImpl()),
      );

  final SendPasswordResetOtp _sendResetOtp;

  @override
  Widget build(BuildContext context) {
    return EmailVerificationScreen(
      onRequestOtp: (email) async {
        final result = await _sendResetOtp(email);
        return result.fold((failure) => failure.message, (_) => null);
      },
      onOtpVerified: (resetToken) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => ResetPasswordScreen(resetToken: resetToken),
          ),
        );
      },
    );
  }
}
