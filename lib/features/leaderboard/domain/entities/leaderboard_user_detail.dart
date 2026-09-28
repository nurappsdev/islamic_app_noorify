import 'package:islami_app_noorify/features/leaderboard/domain/entities/leaderboard_board.dart';
import 'package:islami_app_noorify/features/leaderboard/domain/entities/leaderboard_entry.dart';

/// The leader of the period, as sent alongside every user's position.
class LeaderboardFirstPlace {
  const LeaderboardFirstPlace({
    required this.userId,
    required this.name,
    required this.avatarUrl,
    required this.points,
    this.badge,
  });

  final String userId;
  final String name;
  final String? avatarUrl;
  final num points;
  final LeaderboardBadge? badge;
}

/// One user's standing for one period
/// (`GET /leaderboard/users/:userId?period=...&date=...`).
class LeaderboardUserDetail {
  const LeaderboardUserDetail({
    required this.period,
    required this.isRanked,
    required this.rank,
    required this.points,
    required this.name,
    required this.avatarUrl,
    required this.totalParticipants,
    required this.isFirst,
    this.badge,
    this.pointsBehindFirst,
    this.pointsBehindNext,
    this.firstPlace,
  });

  final LeaderboardPeriod period;

  /// `false` when the user has no standing in [period] (no points yet).
  final bool isRanked;

  /// `null` for an unranked user.
  final int? rank;
  final num points;
  final String name;
  final String? avatarUrl;
  final LeaderboardBadge? badge;
  final int totalParticipants;
  final bool isFirst;

  /// `null` when the server didn't send it (e.g. for the leader).
  final num? pointsBehindFirst;
  final num? pointsBehindNext;
  final LeaderboardFirstPlace? firstPlace;
}
