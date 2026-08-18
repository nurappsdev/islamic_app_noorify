class SignUpState {
  const SignUpState({
    this.obscurePassword = true,
    this.obscureConfirm = true,
    this.saveInfo = true,
    this.isLoading = false,
  });

  final bool obscurePassword;
  final bool obscureConfirm;
  final bool saveInfo;
  final bool isLoading;

  SignUpState copyWith({
    bool? obscurePassword,
    bool? obscureConfirm,
    bool? saveInfo,
    bool? isLoading,
  }) {
    return SignUpState(
      obscurePassword: obscurePassword ?? this.obscurePassword,
      obscureConfirm: obscureConfirm ?? this.obscureConfirm,
      saveInfo: saveInfo ?? this.saveInfo,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
