import 'package:islami_app_noorify/features/leaderboard/domain/entities/leaderboard_entry.dart';

/// The resolved date window a leaderboard was computed for.
class LeaderboardPeriod {
  const LeaderboardPeriod({
    required this.type,
    required this.key,
    required this.label,
    required this.from,
    required this.to,
  });

  final String type;
  final String key;
  final String label;
  final String from;
  final String to;
}

class LeaderboardMeta {
  const LeaderboardMeta({
    required this.limit,
    required this.totalParticipants,
    required this.isCurrentUserInTop,
  });

  final int limit;
  final int totalParticipants;
  final bool isCurrentUserInTop;
}

/// The signed-in user's own standing, sent by the server only when they
/// aren't already present in [LeaderboardBoard.entries] (i.e.
/// `!meta.isCurrentUserInTop`).
class LeaderboardMyPosition {
  const LeaderboardMyPosition({
    required this.rank,
    required this.points,
    this.name,
    this.avatarUrl,
    this.pointsToNextRank,
    this.nextRank,
  });

  final int rank;
  final num points;
  final String? name;
  final String? avatarUrl;

  /// How many more points are needed to reach [nextRank]. `null` when the
  /// server didn't include it (e.g. already at rank 1).
  final num? pointsToNextRank;
  final int? nextRank;
}

/// The full payload of `GET /leaderboard/top?period=daily|weekly|monthly|yearly&limit=N`.
class LeaderboardBoard {
  const LeaderboardBoard({
    required this.period,
    required this.meta,
    required this.entries,
    required this.isRanked,
    this.myPosition,
  });

  final LeaderboardPeriod period;
  final LeaderboardMeta meta;
  final List<LeaderboardEntry> entries;
  final LeaderboardMyPosition? myPosition;
  final bool isRanked;
}
