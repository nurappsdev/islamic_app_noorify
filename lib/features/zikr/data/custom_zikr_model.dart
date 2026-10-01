/// One entry in the Home Screen's "My Created Zikr" list — either one of the
/// three seeded defaults (SubhanAllah / Alhamdulillah / Allahu Akbar) or a
/// zikr the user added through the "New Zikr" form. Persisted by
/// `CustomZikrStore` in `HiveService.customZikr`.
class CustomZikrModel {
  const CustomZikrModel({
    required this.id,
    required this.name,
    required this.arabic,
    required this.transliteration,
    required this.target,
    required this.currentCount,
    required this.createdAt,
    this.nameKey,
    this.completed = false,
    this.lastPerformedAt,
  });

  /// Unique, stable id — the Hive key and the suffix of the `ZikrItem`
  /// tracking key (`custom:<id>`) used when this zikr is opened in
  /// `ZikrCounterScreen`.
  final String id;

  final String name;
  final String arabic;
  final String transliteration;
  final int target;
  final int currentCount;

  /// When set (one of `subhanAllah` / `alhamdulillah` / `allahuAkbar`), the
  /// display name follows the app's active language via
  /// `localizedSeedZikrName` instead of the stored [name].
  final String? nameKey;

  final bool completed;
  final DateTime createdAt;
  final DateTime? lastPerformedAt;

  CustomZikrModel copyWith({
    int? currentCount,
    bool? completed,
    DateTime? lastPerformedAt,
  }) => CustomZikrModel(
    id: id,
    name: name,
    arabic: arabic,
    transliteration: transliteration,
    target: target,
    currentCount: currentCount ?? this.currentCount,
    createdAt: createdAt,
    nameKey: nameKey,
    completed: completed ?? this.completed,
    lastPerformedAt: lastPerformedAt ?? this.lastPerformedAt,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'arabic': arabic,
    'transliteration': transliteration,
    'target': target,
    'currentCount': currentCount,
    'nameKey': nameKey,
    'completed': completed,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'lastPerformedAt': lastPerformedAt?.millisecondsSinceEpoch,
  };

  factory CustomZikrModel.fromMap(Map<dynamic, dynamic> map) {
    final lastPerformedMillis = map['lastPerformedAt'] as int?;
    return CustomZikrModel(
      id: map['id'] as String,
      name: map['name'] as String,
      arabic: map['arabic'] as String? ?? '',
      transliteration: map['transliteration'] as String? ?? '',
      target: map['target'] as int? ?? 1,
      currentCount: map['currentCount'] as int? ?? 0,
      nameKey: map['nameKey'] as String?,
      completed: map['completed'] as bool? ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] as int? ?? 0,
      ),
      lastPerformedAt: lastPerformedMillis == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(lastPerformedMillis),
    );
  }
}
