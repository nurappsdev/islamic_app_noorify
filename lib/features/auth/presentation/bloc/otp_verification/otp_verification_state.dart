import 'package:islami_app_noorify/core/errors/failures.dart';

enum OtpVerificationStatus { initial, loading, success, failure }

enum OtpResendStatus { idle, sending, sent, failure }

class OtpVerificationState {
  const OtpVerificationState({
    this.status = OtpVerificationStatus.initial,
    this.resendStatus = OtpResendStatus.idle,
    this.message,
    this.failure,
    this.resetToken,
    this.resendMessage,
    this.resendFailure,
  });

  final OtpVerificationStatus status;
  final OtpResendStatus resendStatus;

  /// Verify: server confirmation message on success.
  final String? message;

  /// Verify: short-lived reset token (forgot-password flow only).
  final String? resetToken;

  /// Verify: failure.
  final Failure? failure;

  /// Resend: server confirmation message on success.
  final String? resendMessage;

  /// Resend: failure.
  final Failure? resendFailure;

  bool get isLoading => status == OtpVerificationStatus.loading;
  bool get isResending => resendStatus == OtpResendStatus.sending;

  /// Verify error message, UI-safe.
  String? get errorMessage => failure?.message;

  /// Resend error message, UI-safe.
  String? get resendErrorMessage => resendFailure?.message;

  OtpVerificationState copyWith({
    OtpVerificationStatus? status,
    OtpResendStatus? resendStatus,
    String? message,
    Failure? failure,
    String? resetToken,
    String? resendMessage,
    Failure? resendFailure,
  }) {
    return OtpVerificationState(
      status: status ?? this.status,
      resendStatus: resendStatus ?? this.resendStatus,
      message: message ?? this.message,
      failure: failure ?? this.failure,
      resetToken: resetToken ?? this.resetToken,
      resendMessage: resendMessage ?? this.resendMessage,
      resendFailure: resendFailure ?? this.resendFailure,
    );
  }
}
