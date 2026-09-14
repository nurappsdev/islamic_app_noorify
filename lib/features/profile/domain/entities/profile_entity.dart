import 'package:islami_app_noorify/features/profile/domain/entities/badge_entity.dart';

/// The signed-in user's profile, as returned by `GET /user/me`.
class ProfileEntity {
  const ProfileEntity({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.role,
    this.authProvider,
    this.gender,
    this.preferredLanguage,
    this.profileCompletionPercentage = 0,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    this.agreedToTerms = false,
    this.totalPoints = 0,
    this.currentStreakDays = 0,
    this.globalRankPosition = 0,
    this.badges = const [],
    this.currentBadge,
  });

  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? role;
  final String? authProvider;
  final String? gender;
  final String? preferredLanguage;
  final int profileCompletionPercentage;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final bool agreedToTerms;
  final int totalPoints;
  final int currentStreakDays;
  final int globalRankPosition;
  final List<BadgeEntity> badges;
  final BadgeEntity? currentBadge;
}
