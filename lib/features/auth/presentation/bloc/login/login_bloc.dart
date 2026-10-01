import 'package:bloc/bloc.dart';

import 'package:tuhfatul_muslim/core/storage/session_cleaner.dart';
import 'package:tuhfatul_muslim/features/auth/domain/usecases/login_user.dart';

import 'login_event.dart';
import 'login_state.dart';

export 'login_event.dart';
export 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc(this._loginUser) : super(const LoginState.initial()) {
    on<LoginSubmitted>(_onSubmitted);
    on<LoginReset>((_, emit) => emit(const LoginState.initial()));
  }

  final LoginUser _loginUser;

  Future<void> _onSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    emit(const LoginState.loading());

    final result = await _loginUser(
      LoginParams(
        email: event.email,
        password: event.password,
        fcmToken: event.fcmToken,
      ),
    );

    await result.fold((failure) async => emit(LoginState.failure(failure)), (
      user,
    ) async {
      // Whatever was armed as a Guest must not carry into this account.
      await SessionCleaner.clearGuestAlarms();
      emit(LoginState.success(user));
    });
  }
}
