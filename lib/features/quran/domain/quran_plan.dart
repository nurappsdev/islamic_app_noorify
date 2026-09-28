class QuranPlan {
  const QuranPlan({
    required this.id,
    required this.name,
    required this.days,
    required this.startSurah,
    required this.startSurahName,
    required this.endSurah,
    required this.endSurahName,
    required this.createdAt,
    this.isCompleted = false,
    this.completedDays = 0,
  });

  final String id;
  final String name;
  final int days;
  final int startSurah;
  final String startSurahName;
  final int endSurah;
  final String endSurahName;
  final DateTime createdAt;
  final bool isCompleted;
  final int completedDays;

  QuranPlan copyWith({
    String? id,
    String? name,
    int? days,
    int? startSurah,
    String? startSurahName,
    int? endSurah,
    String? endSurahName,
    DateTime? createdAt,
    bool? isCompleted,
    int? completedDays,
  }) => QuranPlan(
    id: id ?? this.id,
    name: name ?? this.name,
    days: days ?? this.days,
    startSurah: startSurah ?? this.startSurah,
    startSurahName: startSurahName ?? this.startSurahName,
    endSurah: endSurah ?? this.endSurah,
    endSurahName: endSurahName ?? this.endSurahName,
    createdAt: createdAt ?? this.createdAt,
    isCompleted: isCompleted ?? this.isCompleted,
    completedDays: completedDays ?? this.completedDays,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'days': days,
    'startSurah': startSurah,
    'startSurahName': startSurahName,
    'endSurah': endSurah,
    'endSurahName': endSurahName,
    'createdAt': createdAt.toIso8601String(),
    'isCompleted': isCompleted,
    'completedDays': completedDays,
  };

  factory QuranPlan.fromJson(Map<String, dynamic> json) => QuranPlan(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    days: (json['days'] as num?)?.toInt() ?? 30,
    startSurah: (json['startSurah'] as num?)?.toInt() ?? 1,
    startSurahName: json['startSurahName'] as String? ?? 'Al-Fatiha',
    endSurah: (json['endSurah'] as num?)?.toInt() ?? 114,
    endSurahName: json['endSurahName'] as String? ?? 'An-Nas',
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    isCompleted: json['isCompleted'] as bool? ?? false,
    completedDays: (json['completedDays'] as num?)?.toInt() ?? 0,
  );
}
