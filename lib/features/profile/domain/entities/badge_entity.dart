/// A gamification badge, either one the user has unlocked (as returned in
/// `badges`) or their showcased `currentBadge`.
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
  });

  final String id;
  final String slug;
  final String name;
  final String? iconUrl;
  final String? imageUrl;
  final int level;
  final bool isUnlocked;
  final String? unlockedAt;
}
