import 'package:bloc/bloc.dart';

import 'package:islami_app_noorify/features/auth/domain/usecases/reset_password.dart';

import 'reset_password_event.dart';
import 'reset_password_state.dart';

export 'reset_password_event.dart';
export 'reset_password_state.dart';

class ResetPasswordBloc extends Bloc<ResetPasswordEvent, ResetPasswordState> {
  ResetPasswordBloc(this._resetPassword)
    : super(const ResetPasswordState.initial()) {
    on<ResetPasswordSubmitted>(_onSubmitted);
    on<ResetPasswordReset>((_, emit) => emit(const ResetPasswordState.initial()));
  }

  final ResetPassword _resetPassword;

  Future<void> _onSubmitted(
    ResetPasswordSubmitted event,
    Emitter<ResetPasswordState> emit,
  ) async {
    emit(const ResetPasswordState.loading());

    final result = await _resetPassword(
      ResetPasswordParams(
        resetToken: event.resetToken,
        password: event.password,
        confirmPassword: event.confirmPassword,
      ),
    );

    result.fold(
      (failure) => emit(ResetPasswordState.failure(failure)),
      (message) => emit(ResetPasswordState.success(message)),
    );
  }
}
