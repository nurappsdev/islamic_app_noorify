import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/auth/domain/entities/auth_user.dart';

enum LoginStatus { initial, loading, success, failure }

class LoginState {
  const LoginState._({required this.status, this.user, this.failure});

  const LoginState.initial() : this._(status: LoginStatus.initial);

  const LoginState.loading() : this._(status: LoginStatus.loading);

  const LoginState.success(AuthUser user)
    : this._(status: LoginStatus.success, user: user);

  const LoginState.failure(Failure failure)
    : this._(status: LoginStatus.failure, failure: failure);

  final LoginStatus status;
  final AuthUser? user;
  final Failure? failure;

  bool get isLoading => status == LoginStatus.loading;

  String? get errorMessage => failure?.message;
}
