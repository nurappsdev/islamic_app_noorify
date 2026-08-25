abstract class SignUpEvent {
  const SignUpEvent();
}

class ToggleObscurePassword extends SignUpEvent {
  const ToggleObscurePassword();
}

class ToggleObscureConfirm extends SignUpEvent {
  const ToggleObscureConfirm();
}

class SetSaveInfo extends SignUpEvent {
  const SetSaveInfo(this.value);

  final bool value;
}

class SetLoading extends SignUpEvent {
  const SetLoading(this.value);

  final bool value;
}
