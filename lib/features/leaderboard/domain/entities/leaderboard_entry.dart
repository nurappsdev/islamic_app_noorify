/// A badge earned through the Amol point system, attached to a leaderboard
/// entry (e.g. `{slug: an_noor, name: An-Noor, iconUrl: "", level: 1}`).
class LeaderboardBadge {
  const LeaderboardBadge({
    required this.slug,
    required this.name,
    required this.iconUrl,
    required this.level,
  });

  final String slug;
  final String name;
  final String iconUrl;
  final int level;
}

/// One row of `GET /leaderboard/top` — a ranked participant.
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.name,
    required this.avatarUrl,
    required this.points,
    required this.isCurrentUser,
    this.badge,
  });

  final int rank;
  final String userId;
  final String name;
  final String? avatarUrl;
  final num points;
  final bool isCurrentUser;
  final LeaderboardBadge? badge;
}
