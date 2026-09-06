import 'package:bloc/bloc.dart';

import 'package:islami_app_noorify/features/auth/domain/usecases/register_account.dart';

import 'register_event.dart';
import 'register_state.dart';

export 'register_event.dart';
export 'register_state.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  RegisterBloc(this._registerAccount) : super(const RegisterState.initial()) {
    on<RegisterSubmitted>(_onSubmitted);
    on<RegisterReset>((_, emit) => emit(const RegisterState.initial()));
  }

  final RegisterAccount _registerAccount;

  Future<void> _onSubmitted(
    RegisterSubmitted event,
    Emitter<RegisterState> emit,
  ) async {
    emit(const RegisterState.loading());

    final result = await _registerAccount(
      RegisterParams(
        name: event.name,
        email: event.email,
        password: event.password,
        phone: event.phone,
        gender: event.gender,
      ),
    );

    result.fold(
      (failure) => emit(RegisterState.failure(failure)),
      (user) => emit(RegisterState.success(user)),
    );
  }
}
