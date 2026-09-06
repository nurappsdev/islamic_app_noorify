import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/auth/domain/entities/auth_user.dart';

enum RegisterStatus { initial, loading, success, failure }

class RegisterState {
  const RegisterState._({
    required this.status,
    this.user,
    this.failure,
  });

  const RegisterState.initial() : this._(status: RegisterStatus.initial);

  const RegisterState.loading() : this._(status: RegisterStatus.loading);

  const RegisterState.success(AuthUser user)
    : this._(status: RegisterStatus.success, user: user);

  const RegisterState.failure(Failure failure)
    : this._(status: RegisterStatus.failure, failure: failure);

  final RegisterStatus status;
  final AuthUser? user;
  final Failure? failure;

  bool get isLoading => status == RegisterStatus.loading;

  /// UI-safe error message, or `null` when there is no error.
  String? get errorMessage => failure?.message;
}
