import 'package:tuhfatul_muslim/features/dua/data/models/dua_api_models.dart';

int _asInt(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;

double _asDouble(Object? value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

Map<String, dynamic> _mapOf(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};

/// A Mongo `_id`/`id` read off a *map* — unlike [readId], which only reads a
/// single already-extracted value and must not be handed a whole map (its
/// `toString()` would come back as a non-empty, garbage "id").
String _idOf(Map<String, dynamic> json) =>
    readId(json['_id']) ?? readId(json['id']) ?? '';

/// One dua inside a [DuaPlanDraft] (`items[]` of `POST /duas/planner/plans`
/// and `POST /duas/planner/plans/{id}/items`).
///
/// [targetCount] left `null` lets the API fall back to the dua's own
/// `recommendedRepeatCount`; [slot] defaults to `anytime`.
class DuaPlanItemDraft {
  const DuaPlanItemDraft({
    required this.duaId,
    this.targetCount,
    this.slot = 'anytime',
  });

  final String duaId;
  final int? targetCount;

  /// `morning`, `afternoon`, `evening`, `night` or `anytime`.
  final String slot;

  Map<String, dynamic> toJson() => {
    'duaId': duaId,
    if (targetCount != null && targetCount! > 0) 'targetCount': targetCount,
    'slot': slot,
  };
}

/// What the user filled in to create a dua plan (`POST /duas/planner/plans`),
/// design `devImg/img_8.png` — one or more duas (design's "Add"/"Add More"),
/// each with its own target count and time slot.
///
/// `startDate`/`endDate`/reminder fields are left out so the plan simply
/// starts today and has no end date.
class DuaPlanDraft {
  const DuaPlanDraft({
    required this.name,
    required this.items,
    this.daysOfWeek = const [0, 1, 2, 3, 4, 5, 6],
  });

  final String name;
  final List<DuaPlanItemDraft> items;

  /// 0 = Sunday ... 6 = Saturday.
  final List<int> daysOfWeek;

  Map<String, dynamic> toJson() => {
    'name': name,
    'items': [for (final item in items) item.toJson()],
    'daysOfWeek': daysOfWeek,
  };
}

/// One of the user's dua plans, as `GET /duas/planner/plans` lists them —
/// CONFIRMED real response (2026-10-14): `totalDuas` is top-level, today's
/// progress (`completedDuas`/`percentage`/`isCompleted`) is nested under
/// `today`, and streak stats are nested under `stats`.
class DuaPlan {
  const DuaPlan({
    required this.id,
    required this.name,
    required this.status,
    required this.totalDuas,
    required this.completedDuas,
    required this.percentage,
    required this.isCompleted,
    required this.currentStreak,
    required this.longestStreak,
  });

  final String id;
  final String name;

  /// `in_progress`, `completed` or `abandoned`.
  final String status;
  final int totalDuas;

  /// Today's progress: how many of [totalDuas] are done so far.
  final int completedDuas;

  /// Today's progress share, `0..100`.
  final double percentage;
  final bool isCompleted;
  final int currentStreak;
  final int longestStreak;

  factory DuaPlan.fromJson(Map<String, dynamic> json) {
    final today = _mapOf(json['today']);
    final stats = _mapOf(json['stats']);
    return DuaPlan(
      id: _idOf(json),
      name: json['name']?.toString() ?? '',
      status: json['status']?.toString() ?? 'in_progress',
      totalDuas: _asInt(json['totalDuas']),
      completedDuas: _asInt(today['completedDuas']),
      percentage: _asDouble(today['percentage']),
      isCompleted: today['isCompleted'] == true,
      currentStreak: _asInt(stats['currentStreak']),
      longestStreak: _asInt(stats['longestStreak']),
    );
  }
}

/// One page of `GET /duas/planner/plans`, plus its pagination `meta`.
class DuaPlanPage {
  const DuaPlanPage({
    required this.plans,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPage,
  });

  final List<DuaPlan> plans;
  final int page;
  final int limit;
  final int total;
  final int totalPage;

  bool get hasMore => page < totalPage;
}

/// One dua inside a plan, as `GET /duas/planner/plans/{id}` lists them —
/// CONFIRMED real response (2026-10-14): each item embeds the dua's full
/// content under `dua` (same shape `GET /duas/{id}` returns), so no extra
/// request is needed to show it for reading.
class DuaPlanItem {
  const DuaPlanItem({
    required this.duaId,
    required this.targetCount,
    required this.count,
    required this.remaining,
    required this.slot,
    required this.order,
    required this.isCompleted,
    this.dua,
  });

  final String duaId;
  final int targetCount;

  /// Today's recitation count so far.
  final int count;
  final int remaining;
  final String slot;
  final int order;
  final bool isCompleted;

  /// The dua's full content, embedded by the plan detail endpoint. Null only
  /// if a future response leaves it out, in which case the detail screen
  /// falls back to `GET /duas/{id}`.
  final DuaFeaturedModel? dua;

  factory DuaPlanItem.fromJson(Map<String, dynamic> json) {
    final duaJson = json['dua'];
    final duaModel = duaJson is Map
        ? DuaFeaturedModel.fromJson(Map<String, dynamic>.from(duaJson))
        : null;
    return DuaPlanItem(
      duaId: readId(json['duaId']) ?? duaModel?.id ?? _idOf(json),
      targetCount: _asInt(json['targetCount']),
      count: _asInt(json['count']),
      remaining: _asInt(json['remaining']),
      slot: json['slot']?.toString() ?? 'anytime',
      order: _asInt(json['order']),
      isCompleted: json['isCompleted'] == true,
      dua: duaModel,
    );
  }
}

/// A plan with its duas (`GET /duas/planner/plans/{id}`), design
/// `devImg/img_7.png`'s "My Plan" entries opened for reading/reciting.
class DuaPlanDetail {
  const DuaPlanDetail({
    required this.id,
    required this.name,
    required this.status,
    required this.items,
  });

  final String id;
  final String name;

  /// `in_progress`, `completed` or `abandoned`.
  final String status;
  final List<DuaPlanItem> items;

  factory DuaPlanDetail.fromJson(Map<String, dynamic> json) => DuaPlanDetail(
    id: _idOf(json),
    name: json['name']?.toString() ?? '',
    status: json['status']?.toString() ?? 'in_progress',
    items: [
      for (final item in json['items'] as List? ?? const [])
        if (item is Map) DuaPlanItem.fromJson(Map<String, dynamic>.from(item)),
    ]..sort((a, b) => a.order.compareTo(b.order)),
  );
}
