import 'package:islami_app_noorify/core/errors/exceptions.dart';
import 'package:islami_app_noorify/features/auth/domain/entities/auth_user.dart';

/// Data-layer representation of [AuthUser] that knows how to read the API JSON.
///
/// Expected shape (from `POST /auth/register`):
/// ```json
/// {
///   "_id": "6a9d129b55c62f8e28850bce",
///   "name": "John Doe",
///   "email": "john@example.com",
///   "phone": "+8801712345678",
///   "isEmailVerified": false
/// }
/// ```
class AuthUserModel extends AuthUser {
  const AuthUserModel({
    required super.id,
    required super.name,
    required super.email,
    super.phone,
    super.isEmailVerified,
  });

  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    final id = (json['_id'] ?? json['id'])?.toString();
    final email = json['email']?.toString();
    if (id == null || email == null) {
      throw ParsingException('Registration response is missing "_id" / "email".');
    }
    return AuthUserModel(
      id: id,
      name: json['name']?.toString() ?? '',
      email: email,
      phone: json['phone']?.toString(),
      isEmailVerified: json['isEmailVerified'] == true,
    );
  }
}
