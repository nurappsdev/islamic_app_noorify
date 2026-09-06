import 'package:islami_app_noorify/core/errors/failures.dart';

enum ResetPasswordStatus { initial, loading, success, failure }

class ResetPasswordState {
  const ResetPasswordState._({required this.status, this.message, this.failure});

  const ResetPasswordState.initial()
    : this._(status: ResetPasswordStatus.initial);

  const ResetPasswordState.loading()
    : this._(status: ResetPasswordStatus.loading);

  const ResetPasswordState.success(String message)
    : this._(status: ResetPasswordStatus.success, message: message);

  const ResetPasswordState.failure(Failure failure)
    : this._(status: ResetPasswordStatus.failure, failure: failure);

  final ResetPasswordStatus status;
  final String? message;
  final Failure? failure;

  bool get isLoading => status == ResetPasswordStatus.loading;

  String? get errorMessage => failure?.message;
}
