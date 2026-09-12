import 'package:islami_app_noorify/features/home/domain/entities/user_summary.dart';

class UserSummaryModel extends UserSummary {
  const UserSummaryModel({
    required super.fullName,
    required super.greetingText,
    super.avatarUrl,
    super.currentStreakDays,
    super.totalPointsToday,
    super.maxDailyPoints,
    super.percentageToday,
    super.currentBadgeName,
    super.globalRank,
    super.kiblahAngle,
  });

  factory UserSummaryModel.fromJson(Map<String, dynamic> json) {
    return UserSummaryModel(
      fullName: json['fullName']?.toString() ?? '',
      greetingText: json['greetingText']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString(),
      currentStreakDays: (json['currentStreakDays'] as num?)?.toInt() ?? 0,
      totalPointsToday: (json['totalPointsToday'] as num?) ?? 0,
      maxDailyPoints: (json['maxDailyPoints'] as num?) ?? 0,
      percentageToday: (json['percentageToday'] as num?) ?? 0,
      currentBadgeName: json['currentBadgeName']?.toString(),
      globalRank: (json['globalRank'] as num?)?.toInt() ?? 0,
      kiblahAngle: json['kiblahAngle']?.toString(),
    );
  }
}
