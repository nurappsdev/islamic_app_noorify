import 'package:islami_app_noorify/core/errors/exceptions.dart';
import 'package:islami_app_noorify/features/profile/domain/entities/profile_entity.dart';

/// Data-layer representation of [ProfileEntity] that knows how to read the
/// API JSON (`GET /user/me`'s `data` payload) and how to (de)serialize to a
/// plain map for the Hive cache.
///
/// Expected API shape:
/// ```json
/// {
///   "_id": "6aa4db0c50cca935ba07b969",
///   "name": "noorify",
///   "email": "noorify2@yopmail.com",
///   "phone": "+8801712345678",
///   "role": "user",
///   "authProvider": "email",
///   "gender": "male",
///   "preferredLanguage": "bn",
///   "profileCompletionPercentage": 0,
///   "isEmailVerified": true,
///   "isPhoneVerified": false,
///   "agreedToTerms": false,
///   "totalPoints": 0,
///   "currentStreakDays": 0
/// }
/// ```
class ProfileModel extends ProfileEntity {
  const ProfileModel({
    required super.id,
    required super.name,
    required super.email,
    super.phone,
    super.role,
    super.authProvider,
    super.gender,
    super.preferredLanguage,
    super.profileCompletionPercentage,
    super.isEmailVerified,
    super.isPhoneVerified,
    super.agreedToTerms,
    super.totalPoints,
    super.currentStreakDays,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    final id = (json['_id'] ?? json['id'])?.toString();
    final email = json['email']?.toString();
    if (id == null || email == null) {
      throw ParsingException('Profile response is missing "_id" / "email".');
    }
    return ProfileModel(
      id: id,
      name: json['name']?.toString() ?? '',
      email: email,
      phone: json['phone']?.toString(),
      role: json['role']?.toString(),
      authProvider: json['authProvider']?.toString(),
      gender: json['gender']?.toString(),
      preferredLanguage: json['preferredLanguage']?.toString(),
      profileCompletionPercentage:
          (json['profileCompletionPercentage'] as num?)?.toInt() ?? 0,
      isEmailVerified: json['isEmailVerified'] == true,
      isPhoneVerified: json['isPhoneVerified'] == true,
      agreedToTerms: json['agreedToTerms'] == true,
      totalPoints: (json['totalPoints'] as num?)?.toInt() ?? 0,
      currentStreakDays: (json['currentStreakDays'] as num?)?.toInt() ?? 0,
    );
  }

  /// Round-trips through the same key names as [fromJson] so the Hive cache
  /// can be read back with it directly.
  Map<String, dynamic> toJson() => {
    '_id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'role': role,
    'authProvider': authProvider,
    'gender': gender,
    'preferredLanguage': preferredLanguage,
    'profileCompletionPercentage': profileCompletionPercentage,
    'isEmailVerified': isEmailVerified,
    'isPhoneVerified': isPhoneVerified,
    'agreedToTerms': agreedToTerms,
    'totalPoints': totalPoints,
    'currentStreakDays': currentStreakDays,
  };
}
