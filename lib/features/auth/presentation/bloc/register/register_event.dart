abstract class RegisterEvent {
  const RegisterEvent();
}

/// Fired when the user submits the sign-up form.
class RegisterSubmitted extends RegisterEvent {
  const RegisterSubmitted({
    required this.name,
    required this.email,
    required this.password,
    this.phone,
    this.gender,
  });

  final String name;
  final String email;
  final String password;
  final String? phone;
  final String? gender;
}

/// Resets the bloc back to [RegisterInitial] (e.g. after showing an error).
class RegisterReset extends RegisterEvent {
  const RegisterReset();
}
