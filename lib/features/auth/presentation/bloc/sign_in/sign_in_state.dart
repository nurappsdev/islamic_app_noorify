class SignInState {
  const SignInState({this.obscurePassword = true, this.isLoading = false});

  final bool obscurePassword;
  final bool isLoading;

  SignInState copyWith({bool? obscurePassword, bool? isLoading}) {
    return SignInState(
      obscurePassword: obscurePassword ?? this.obscurePassword,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
