abstract class SignInEvent {
  const SignInEvent();
}

class ToggleObscurePassword extends SignInEvent {
  const ToggleObscurePassword();
}

class SetLoading extends SignInEvent {
  const SetLoading(this.value);

  final bool value;
}
