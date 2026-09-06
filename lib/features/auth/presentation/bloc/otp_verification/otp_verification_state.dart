import 'package:islami_app_noorify/core/errors/failures.dart';

enum OtpVerificationStatus { initial, loading, success, failure }

class OtpVerificationState {
  const OtpVerificationState._({
    required this.status,
    this.message,
    this.failure,
  });

  const OtpVerificationState.initial()
    : this._(status: OtpVerificationStatus.initial);

  const OtpVerificationState.loading()
    : this._(status: OtpVerificationStatus.loading);

  const OtpVerificationState.success(String message)
    : this._(status: OtpVerificationStatus.success, message: message);

  const OtpVerificationState.failure(Failure failure)
    : this._(status: OtpVerificationStatus.failure, failure: failure);

  final OtpVerificationStatus status;

  /// Server confirmation message on success.
  final String? message;
  final Failure? failure;

  bool get isLoading => status == OtpVerificationStatus.loading;

  /// UI-safe error message, or `null` when there is no error.
  String? get errorMessage => failure?.message;
}
