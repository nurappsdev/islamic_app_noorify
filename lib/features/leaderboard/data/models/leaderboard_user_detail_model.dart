import 'package:tuhfatul_muslim/features/leaderboard/data/models/leaderboard_board_model.dart';
import 'package:tuhfatul_muslim/features/leaderboard/data/models/leaderboard_entry_model.dart';
import 'package:tuhfatul_muslim/features/leaderboard/domain/entities/leaderboard_entry.dart';
import 'package:tuhfatul_muslim/features/leaderboard/domain/entities/leaderboard_user_detail.dart';

LeaderboardBadge? _badgeFrom(Object? raw) => raw is Map
    ? LeaderboardBadgeModel.fromJson(Map<String, dynamic>.from(raw))
    : null;

/// A blank `avatarUrl` (`null` or `""`) means "no photo".
String? _avatarFrom(Object? raw) {
  final value = raw?.toString().trim();
  return value == null || value.isEmpty ? null : value;
}

class LeaderboardFirstPlaceModel extends LeaderboardFirstPlace {
  const LeaderboardFirstPlaceModel({
    required super.userId,
    required super.name,
    required super.avatarUrl,
    required super.points,
    super.badge,
  });

  factory LeaderboardFirstPlaceModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardFirstPlaceModel(
      userId: json['userId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      avatarUrl: _avatarFrom(json['avatarUrl']),
      points: (json['points'] as num?) ?? 0,
      badge: _badgeFrom(json['badge']),
    );
  }
}

class LeaderboardUserDetailModel extends LeaderboardUserDetail {
  const LeaderboardUserDetailModel({
    required super.period,
    required super.isRanked,
    required super.rank,
    required super.points,
    required super.name,
    required super.avatarUrl,
    required super.totalParticipants,
    required super.isFirst,
    super.badge,
    super.pointsBehindFirst,
    super.pointsBehindNext,
    super.firstPlace,
  });

  factory LeaderboardUserDetailModel.fromJson(Map<String, dynamic> json) {
    final rawPeriod = json['period'];
    final rawFirst = json['firstPlace'];
    return LeaderboardUserDetailModel(
      period: rawPeriod is Map
          ? LeaderboardPeriodModel.fromJson(
              Map<String, dynamic>.from(rawPeriod),
            )
          : const LeaderboardPeriodModel(
              type: '',
              key: '',
              label: '',
              from: '',
              to: '',
            ),
      isRanked: json['isRanked'] == true,
      rank: (json['rank'] as num?)?.toInt(),
      points: (json['points'] as num?) ?? 0,
      name: json['name']?.toString() ?? '',
      avatarUrl: _avatarFrom(json['avatarUrl']),
      badge: _badgeFrom(json['badge']),
      totalParticipants: (json['totalParticipants'] as num?)?.toInt() ?? 0,
      isFirst: json['isFirst'] == true,
      pointsBehindFirst: json['pointsBehindFirst'] as num?,
      pointsBehindNext: json['pointsBehindNext'] as num?,
      firstPlace: rawFirst is Map
          ? LeaderboardFirstPlaceModel.fromJson(
              Map<String, dynamic>.from(rawFirst),
            )
          : null,
    );
  }
}
