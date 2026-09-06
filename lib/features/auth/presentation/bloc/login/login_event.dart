abstract class LoginEvent {
  const LoginEvent();
}

/// Fired when the user submits the sign-in form.
class LoginSubmitted extends LoginEvent {
  const LoginSubmitted({required this.email, required this.password});

  final String email;
  final String password;
}

/// Resets the bloc back to its initial state (e.g. after showing an error).
class LoginReset extends LoginEvent {
  const LoginReset();
}
