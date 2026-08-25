import 'package:bloc/bloc.dart';

import 'sign_up_event.dart';
import 'sign_up_state.dart';

export 'sign_up_event.dart';
export 'sign_up_state.dart';

class SignUpBloc extends Bloc<SignUpEvent, SignUpState> {
  SignUpBloc() : super(const SignUpState()) {
    on<ToggleObscurePassword>((event, emit) {
      emit(state.copyWith(obscurePassword: !state.obscurePassword));
    });

    on<ToggleObscureConfirm>((event, emit) {
      emit(state.copyWith(obscureConfirm: !state.obscureConfirm));
    });

    on<SetSaveInfo>((event, emit) {
      if (state.saveInfo != event.value) {
        emit(state.copyWith(saveInfo: event.value));
      }
    });

    on<SetLoading>((event, emit) {
      if (state.isLoading != event.value) {
        emit(state.copyWith(isLoading: event.value));
      }
    });
  }
}
