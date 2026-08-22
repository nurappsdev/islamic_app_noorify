import 'package:bloc/bloc.dart';

import 'sign_in_state.dart';

export 'sign_in_state.dart';

class SignInCubit extends Cubit<SignInState> {
  SignInCubit() : super(const SignInState());

  void toggleObscurePassword() {
    emit(state.copyWith(obscurePassword: !state.obscurePassword));
  }

  void setLoading(bool value) {
    if (state.isLoading != value) emit(state.copyWith(isLoading: value));
  }
}
