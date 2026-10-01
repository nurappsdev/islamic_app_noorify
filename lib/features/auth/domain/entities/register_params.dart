/// Value object describing everything needed to register a new account.
class RegisterParams {
  const RegisterParams({
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

  /// Cheap client-side checks so we never fire an obviously bad request.
  /// Returns an error message, or `null` when the params look valid.
  String? validate() {
    if (name.trim().length < 2) {
      return 'Please enter your full name.';
    }
    if (!_emailPattern.hasMatch(email.trim())) {
      return 'Please enter a valid email address.';
    }
    if (password.length < 8 ||
        !password.contains(RegExp(r'[A-Z]')) ||
        !password.contains(RegExp(r'[0-9]')) ||
        !password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-]'))) {
      return 'Password must be at least 8 characters and include an '
          'uppercase letter, a number and a special character.';
    }
    return null;
  }

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
}
