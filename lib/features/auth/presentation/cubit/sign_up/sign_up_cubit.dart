import 'package:bloc/bloc.dart';

import 'sign_up_state.dart';

export 'sign_up_state.dart';

class SignUpCubit extends Cubit<SignUpState> {
  SignUpCubit() : super(const SignUpState());

  void toggleObscurePassword() {
    emit(state.copyWith(obscurePassword: !state.obscurePassword));
  }

  void toggleObscureConfirm() {
    emit(state.copyWith(obscureConfirm: !state.obscureConfirm));
  }

  void setSaveInfo(bool value) {
    if (state.saveInfo != value) emit(state.copyWith(saveInfo: value));
  }

  void setLoading(bool value) {
    if (state.isLoading != value) emit(state.copyWith(isLoading: value));
  }
}
