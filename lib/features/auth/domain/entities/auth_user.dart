/// A user account as returned by the backend after registration / login.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.isEmailVerified = false,
  });

  final String id;
  final String name;
  final String email;
  final String? phone;
  final bool isEmailVerified;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUser &&
          other.id == id &&
          other.name == name &&
          other.email == email &&
          other.phone == phone &&
          other.isEmailVerified == isEmailVerified;

  @override
  int get hashCode => Object.hash(id, name, email, phone, isEmailVerified);
}
