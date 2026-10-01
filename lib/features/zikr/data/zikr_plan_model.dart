/// One zikr inside a [ZikrPlanModel], with its own target and progress.
class PlanZikrItem {
  const PlanZikrItem({
    required this.name,
    required this.target,
    this.nameKey,
    this.currentCount = 0,
  });

  final String name;

  /// When set (one of `subhanAllah` / `alhamdulillah` / `allahuAkbar`), the
  /// display name follows the app's active language via
  /// `localizedSeedZikrName` instead of the stored [name].
  final String? nameKey;

  final int target;
  final int currentCount;

  bool get isDone => currentCount >= target;

  PlanZikrItem copyWith({int? currentCount}) => PlanZikrItem(
    name: name,
    nameKey: nameKey,
    target: target,
    currentCount: currentCount ?? this.currentCount,
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'nameKey': nameKey,
    'target': target,
    'currentCount': currentCount,
  };

  factory PlanZikrItem.fromMap(Map<dynamic, dynamic> map) => PlanZikrItem(
    name: map['name'] as String,
    nameKey: map['nameKey'] as String?,
    target: map['target'] as int? ?? 1,
    currentCount: map['currentCount'] as int? ?? 0,
  );
}

/// A Zikr planner plan — name, duration, and the zikr/targets selected for
/// it. Persisted by `ZikrPlannerStore` in `HiveService.zikrPlanner`.
class ZikrPlanModel {
  const ZikrPlanModel({
    required this.id,
    required this.name,
    required this.durationDays,
    required this.items,
    required this.createdAt,
    this.completed = false,
    this.completedAt,
  });

  final String id;
  final String name;
  final int durationDays;
  final List<PlanZikrItem> items;
  final DateTime createdAt;
  final bool completed;
  final DateTime? completedAt;

  int get totalTarget => items.fold(0, (sum, item) => sum + item.target);
  int get totalDone => items.fold(0, (sum, item) => sum + item.currentCount);

  /// Every selected zikr has reached its target.
  bool get isFullyDone =>
      items.isNotEmpty && items.every((item) => item.isDone);

  ZikrPlanModel copyWith({
    List<PlanZikrItem>? items,
    bool? completed,
    DateTime? completedAt,
  }) => ZikrPlanModel(
    id: id,
    name: name,
    durationDays: durationDays,
    items: items ?? this.items,
    createdAt: createdAt,
    completed: completed ?? this.completed,
    completedAt: completedAt ?? this.completedAt,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'durationDays': durationDays,
    'items': [for (final item in items) item.toMap()],
    'createdAt': createdAt.millisecondsSinceEpoch,
    'completed': completed,
    'completedAt': completedAt?.millisecondsSinceEpoch,
  };

  factory ZikrPlanModel.fromMap(Map<dynamic, dynamic> map) {
    final completedMillis = map['completedAt'] as int?;
    return ZikrPlanModel(
      id: map['id'] as String,
      name: map['name'] as String,
      durationDays: map['durationDays'] as int? ?? 1,
      items: [
        for (final raw in (map['items'] as List? ?? const []))
          PlanZikrItem.fromMap(raw as Map<dynamic, dynamic>),
      ],
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] as int? ?? 0,
      ),
      completed: map['completed'] as bool? ?? false,
      completedAt: completedMillis == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(completedMillis),
    );
  }
}
