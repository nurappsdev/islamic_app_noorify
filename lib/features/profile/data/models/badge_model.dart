import 'package:islami_app_noorify/features/profile/domain/entities/badge_entity.dart';

/// Data-layer representation of [BadgeEntity]. Used both for entries in
/// `badges` (which carry `_id` / `unlockedAt` / `isUnlocked`) and for
/// `currentBadge` (which only carries `slug` / `name` / `iconUrl` / `level`).
class BadgeModel extends BadgeEntity {
  const BadgeModel({
    required super.id,
    required super.slug,
    required super.name,
    super.iconUrl,
    super.imageUrl,
    super.level,
    super.isUnlocked,
    super.unlockedAt,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    final slug = json['slug']?.toString() ?? '';
    return BadgeModel(
      id: (json['_id'] ?? json['id'])?.toString() ?? slug,
      slug: slug,
      name: json['name']?.toString() ?? '',
      iconUrl: json['iconUrl']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      level: (json['level'] as num?)?.toInt() ?? 0,
      isUnlocked: json['isUnlocked'] == true,
      unlockedAt: json['unlockedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'slug': slug,
    'name': name,
    'iconUrl': iconUrl,
    'imageUrl': imageUrl,
    'level': level,
    'isUnlocked': isUnlocked,
    'unlockedAt': unlockedAt,
  };
}
