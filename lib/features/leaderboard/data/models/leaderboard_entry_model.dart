import 'package:islami_app_noorify/features/leaderboard/domain/entities/leaderboard_entry.dart';

class LeaderboardBadgeModel extends LeaderboardBadge {
  const LeaderboardBadgeModel({
    required super.slug,
    required super.name,
    required super.iconUrl,
    required super.level,
  });

  factory LeaderboardBadgeModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardBadgeModel(
      slug: json['slug']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      iconUrl: json['iconUrl']?.toString() ?? '',
      level: (json['level'] as num?)?.toInt() ?? 0,
    );
  }
}

class LeaderboardEntryModel extends LeaderboardEntry {
  const LeaderboardEntryModel({
    required super.rank,
    required super.userId,
    required super.name,
    required super.avatarUrl,
    required super.points,
    required super.isCurrentUser,
    super.badge,
  });

  factory LeaderboardEntryModel.fromJson(Map<String, dynamic> json) {
    final rawBadge = json['badge'];
    final badge = rawBadge is Map
        ? LeaderboardBadgeModel.fromJson(Map<String, dynamic>.from(rawBadge))
        : null;

    return LeaderboardEntryModel(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      userId: json['userId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString(),
      points: (json['points'] as num?) ?? 0,
      isCurrentUser: json['isCurrentUser'] == true,
      badge: badge,
    );
  }
}
