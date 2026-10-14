import 'package:tuhfatul_muslim/features/dua/data/models/dua_api_models.dart';

int _asInt(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;

double _asDouble(Object? value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

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

/// One of the user's dua plans, as `GET /duas/planner/plans` lists them and
/// `POST /duas/planner/plans` returns on success.
///
/// The API's published spec documents these fields only by description (no
/// example response body), so this is parsed defensively, same as the rest
/// of this app's API models.
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
  final int completedDuas;

  /// Today's progress share, `0..100`.
  final double percentage;
  final bool isCompleted;
  final int currentStreak;
  final int longestStreak;

  factory DuaPlan.fromJson(Map<String, dynamic> json) => DuaPlan(
    id: readId(json) ?? '',
    name: json['name']?.toString() ?? '',
    status: json['status']?.toString() ?? 'in_progress',
    totalDuas: _asInt(json['totalDuas']),
    completedDuas: _asInt(json['completedDuas']),
    percentage: _asDouble(json['percentage']),
    isCompleted: json['isCompleted'] == true,
    currentStreak: _asInt(json['currentStreak']),
    longestStreak: _asInt(json['longestStreak']),
  );
}

/// One dua inside a plan, as `GET /duas/planner/plans/{id}` lists them —
/// today's target/count/slot for that dua. The dua's own content (title,
/// arabic, ...) isn't guaranteed to be embedded here, so the plan detail
/// screen fetches it separately via `GET /duas/{id}`.
class DuaPlanItem {
  const DuaPlanItem({
    required this.duaId,
    required this.targetCount,
    required this.count,
    required this.slot,
  });

  final String duaId;
  final int targetCount;

  /// Today's recitation count so far.
  final int count;
  final String slot;

  bool get isDone => targetCount > 0 && count >= targetCount;

  factory DuaPlanItem.fromJson(Map<String, dynamic> json) {
    final nestedDua = json['dua'];
    final duaId =
        readId(json['duaId']) ??
        (nestedDua is Map
            ? readId(Map<String, dynamic>.from(nestedDua))
            : null) ??
        readId(json) ??
        '';
    return DuaPlanItem(
      duaId: duaId,
      targetCount: _asInt(json['targetCount']),
      count: _asInt(
        json['count'] ?? json['currentCount'] ?? json['todayCount'],
      ),
      slot: json['slot']?.toString() ?? 'anytime',
    );
  }
}

/// A plan with its duas (`GET /duas/planner/plans/{id}`), design
/// `devImg/img_7.png`'s "My Plan" entries opened for reading/reciting.
class DuaPlanDetail {
  const DuaPlanDetail({
    required this.id,
    required this.name,
    required this.items,
  });

  final String id;
  final String name;
  final List<DuaPlanItem> items;

  factory DuaPlanDetail.fromJson(Map<String, dynamic> json) => DuaPlanDetail(
    id: readId(json) ?? '',
    name: json['name']?.toString() ?? '',
    items: [
      for (final item in json['items'] as List? ?? const [])
        if (item is Map) DuaPlanItem.fromJson(Map<String, dynamic>.from(item)),
    ],
  );
}
