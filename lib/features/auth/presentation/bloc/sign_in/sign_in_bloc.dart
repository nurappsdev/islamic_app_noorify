import 'package:bloc/bloc.dart';

import 'sign_in_event.dart';
import 'sign_in_state.dart';

export 'sign_in_event.dart';
export 'sign_in_state.dart';

class SignInBloc extends Bloc<SignInEvent, SignInState> {
  SignInBloc() : super(const SignInState()) {
    on<ToggleObscurePassword>((event, emit) {
      emit(state.copyWith(obscurePassword: !state.obscurePassword));
    });

    on<SetLoading>((event, emit) {
      if (state.isLoading != event.value) {
        emit(state.copyWith(isLoading: event.value));
      }
    });
  }
}
