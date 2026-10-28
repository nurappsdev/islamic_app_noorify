import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/auth/domain/entities/auth_user.dart';

import 'package:tuhfatul_muslim/core/storage/session_cleaner.dart';
import 'package:tuhfatul_muslim/features/auth/domain/usecases/login_user.dart';
import 'package:tuhfatul_muslim/features/auth/domain/usecases/google_sign_in_user.dart';

import 'login_event.dart';
import 'login_state.dart';

export 'login_event.dart';
export 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc(this._loginUser, [this._googleSignInUser])
    : super(const LoginState.initial()) {
    on<LoginSubmitted>(_onSubmitted);
    on<GoogleLoginSubmitted>(_onGoogleSubmitted);
    on<LoginReset>((_, emit) => emit(const LoginState.initial()));
  }

  final LoginUser _loginUser;

  /// Only supplied by screens that offer a Google button.
  final GoogleSignInUser? _googleSignInUser;

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

    await _emitResult(result, emit);
  }

  Future<void> _onGoogleSubmitted(
    GoogleLoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    final googleSignInUser = _googleSignInUser;
    if (googleSignInUser == null) {
      emit(
        const LoginState.failure(
          UnknownFailure('Google sign-in is not available here.'),
        ),
      );
      return;
    }

    emit(const LoginState.loading());

    final result = await googleSignInUser(
      GoogleSignInParams(
        idToken: event.idToken,
        email: event.email,
        displayName: event.displayName,
        photoUrl: event.photoUrl,
        fcmToken: event.fcmToken,
      ),
    );

    await _emitResult(result, emit);
  }

  Future<void> _emitResult(
    Either<Failure, AuthUser> result,
    Emitter<LoginState> emit,
  ) async {
    await result.fold((failure) async => emit(LoginState.failure(failure)), (
      user,
    ) async {
      // Whatever was armed as a Guest must not carry into this account.
      await SessionCleaner.clearGuestAlarms();
      emit(LoginState.success(user));
    });
  }
}
