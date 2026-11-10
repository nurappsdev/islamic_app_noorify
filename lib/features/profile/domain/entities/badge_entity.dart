/// A badge: one of the point tiers an admin sets up, reached once the user's
/// total points get to [startPoints]. As returned in `badges` (every tier,
/// with [isUnlocked]), `currentBadge` (the highest reached) and `nextBadge`.
class BadgeEntity {
  const BadgeEntity({
    required this.id,
    required this.slug,
    required this.name,
    this.iconUrl,
    this.imageUrl,
    this.level = 0,
    this.isUnlocked = false,
    this.unlockedAt,
    this.startPoints = 0,
    this.endPoints = 0,
  });

  final String id;
  final String slug;
  final String name;
  final String? iconUrl;
  final String? imageUrl;
  final int level;
  final bool isUnlocked;
  final String? unlockedAt;

  /// The tier's points range.
  final num startPoints, endPoints;
}
