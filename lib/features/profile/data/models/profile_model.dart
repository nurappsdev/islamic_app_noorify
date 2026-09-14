import 'package:islami_app_noorify/core/errors/exceptions.dart';
import 'package:islami_app_noorify/features/profile/data/models/badge_model.dart';
import 'package:islami_app_noorify/features/profile/domain/entities/badge_entity.dart';
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
    super.globalRankPosition,
    super.badges,
    super.currentBadge,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    final id = (json['_id'] ?? json['id'])?.toString();
    final email = json['email']?.toString();
    if (id == null || email == null) {
      throw ParsingException('Profile response is missing "_id" / "email".');
    }
    final badgesJson = json['badges'];
    final currentBadgeJson = json['currentBadge'];
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
      globalRankPosition: (json['globalRankPosition'] as num?)?.toInt() ?? 0,
      badges: badgesJson is List
          ? badgesJson
                .whereType<Map>()
                .map((e) => BadgeModel.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : const [],
      currentBadge: currentBadgeJson is Map
          ? BadgeModel.fromJson(Map<String, dynamic>.from(currentBadgeJson))
          : null,
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
    'globalRankPosition': globalRankPosition,
    'badges': badges
        .map((b) => (b is BadgeModel ? b : _toBadgeModel(b)).toJson())
        .toList(),
    'currentBadge': currentBadge == null
        ? null
        : (currentBadge is BadgeModel
                  ? currentBadge as BadgeModel
                  : _toBadgeModel(currentBadge!))
              .toJson(),
  };

  static BadgeModel _toBadgeModel(BadgeEntity b) => BadgeModel(
    id: b.id,
    slug: b.slug,
    name: b.name,
    iconUrl: b.iconUrl,
    imageUrl: b.imageUrl,
    level: b.level,
    isUnlocked: b.isUnlocked,
    unlockedAt: b.unlockedAt,
  );
}
