/// A user's Quran reading plan.
///
/// Follows the server schema (`/quran/plans`), keeping [counts] and
/// [schedule] as calculated by the server. Retains convenience getters
/// ([days], [isCompleted], [completedDays], [startSurah], [endSurah])
/// so existing navigation and widgets remain compatible.
class QuranPlan {
  const QuranPlan({
    required this.id,
    this.userId = '',
    required this.name,
    this.description,
    this.surahNumbers = const [],
    this.paraNumbers = const [],
    this.wholeQuran = true,
    int? targetDays,
    int? days,
    this.startDate = '',
    this.status = 'in_progress',
    this.completedAt,
    this.isActive = true,
    required this.createdAt,
    DateTime? updatedAt,
    QuranPlanCounts? counts,
    QuranPlanSchedule? schedule,
    this.surahs = const [],
    this.paras = const [],
    this.nextAyah,
    this.startSurah = 1,
    this.startSurahName = 'Al-Fatiha',
    this.endSurah = 114,
    this.endSurahName = 'An-Nas',
  }) : _targetDays = targetDays ?? days ?? 30,
       _counts = counts ?? const QuranPlanCounts(),
       _schedule = schedule ?? const QuranPlanSchedule(),
       updatedAt = updatedAt ?? createdAt;

  final String id;
  final String userId;
  final String name;
  final String? description;
  final List<int> surahNumbers;
  final List<int> paraNumbers;
  final bool wholeQuran;
  final int? _targetDays;
  int get targetDays => _targetDays ?? 30;
  final String startDate;
  final String status;
  final DateTime? completedAt;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final QuranPlanCounts? _counts;
  QuranPlanCounts get counts => _counts ?? const QuranPlanCounts();
  final QuranPlanSchedule? _schedule;
  QuranPlanSchedule get schedule => _schedule ?? const QuranPlanSchedule();
  final List<QuranPlanSurah> surahs;
  final List<QuranPlanPara> paras;
  final QuranPlanNextAyah? nextAyah;

  // Compatibility aliases
  int get days => targetDays;
  bool get isCompleted => status == 'completed' || counts.isCompleted;
  int get completedDays => schedule.dayNumber;
  final int startSurah;
  final String startSurahName;
  final int endSurah;
  final String endSurahName;

  QuranPlan copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    List<int>? surahNumbers,
    List<int>? paraNumbers,
    bool? wholeQuran,
    int? targetDays,
    String? startDate,
    String? status,
    bool? isCompleted,
    DateTime? completedAt,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    QuranPlanCounts? counts,
    QuranPlanSchedule? schedule,
    List<QuranPlanSurah>? surahs,
    List<QuranPlanPara>? paras,
    QuranPlanNextAyah? nextAyah,
    int? startSurah,
    String? startSurahName,
    int? endSurah,
    String? endSurahName,
  }) => QuranPlan(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    name: name ?? this.name,
    description: description ?? this.description,
    surahNumbers: surahNumbers ?? this.surahNumbers,
    paraNumbers: paraNumbers ?? this.paraNumbers,
    wholeQuran: wholeQuran ?? this.wholeQuran,
    targetDays: targetDays ?? this.targetDays,
    startDate: startDate ?? this.startDate,
    status:
        status ??
        (isCompleted != null
            ? (isCompleted ? 'completed' : 'in_progress')
            : this.status),
    completedAt: completedAt ?? this.completedAt,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    counts: counts ?? this.counts,
    schedule: schedule ?? this.schedule,
    surahs: surahs ?? this.surahs,
    paras: paras ?? this.paras,
    nextAyah: nextAyah ?? this.nextAyah,
    startSurah: startSurah ?? this.startSurah,
    startSurahName: startSurahName ?? this.startSurahName,
    endSurah: endSurah ?? this.endSurah,
    endSurahName: endSurahName ?? this.endSurahName,
  );

  Map<String, dynamic> toJson() => {
    '_id': id,
    'id': id,
    'userId': userId,
    'name': name,
    if (description != null) 'description': description,
    'surahNumbers': surahNumbers,
    'paraNumbers': paraNumbers,
    'wholeQuran': wholeQuran,
    'targetDays': targetDays,
    'days': targetDays,
    'startDate': startDate,
    'status': status,
    'completedAt': completedAt?.toIso8601String(),
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'counts': counts.toJson(),
    'schedule': schedule.toJson(),
    'surahs': surahs.map((s) => s.toJson()).toList(),
    'paras': paras.map((p) => p.toJson()).toList(),
    if (nextAyah != null) 'nextAyah': nextAyah!.toJson(),
    'startSurah': startSurah,
    'startSurahName': startSurahName,
    'endSurah': endSurah,
    'endSurahName': endSurahName,
  };

  factory QuranPlan.fromJson(Map<String, dynamic> json) {
    final surahs =
        (json['surahNumbers'] as List?)
            ?.map((e) => (e as num).toInt())
            .toList() ??
        const <int>[];
    final paras =
        (json['paraNumbers'] as List?)
            ?.map((e) => (e as num).toInt())
            .toList() ??
        const <int>[];

    final countsJson = json['counts'];
    final scheduleJson = json['schedule'];

    final surahList =
        (json['surahs'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(QuranPlanSurah.fromJson)
            .toList() ??
        const <QuranPlanSurah>[];
    final paraList =
        (json['paras'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(QuranPlanPara.fromJson)
            .toList() ??
        const <QuranPlanPara>[];
    final nextAyahJson = json['nextAyah'];

    final startS =
        (json['startSurah'] as num?)?.toInt() ??
        (surahs.isNotEmpty ? surahs.first : 1);
    final endS =
        (json['endSurah'] as num?)?.toInt() ??
        (surahs.isNotEmpty ? surahs.last : 114);

    return QuranPlan(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      surahNumbers: surahs,
      paraNumbers: paras,
      wholeQuran: json['wholeQuran'] as bool? ?? true,
      targetDays:
          (json['targetDays'] as num?)?.toInt() ??
          (json['days'] as num?)?.toInt() ??
          30,
      startDate: json['startDate'] as String? ?? '',
      status:
          json['status'] as String? ??
          ((json['isCompleted'] as bool? ?? false)
              ? 'completed'
              : 'in_progress'),
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      counts: countsJson is Map<String, dynamic>
          ? QuranPlanCounts.fromJson(countsJson)
          : const QuranPlanCounts(),
      schedule: scheduleJson is Map<String, dynamic>
          ? QuranPlanSchedule.fromJson(scheduleJson)
          : const QuranPlanSchedule(),
      surahs: surahList,
      paras: paraList,
      nextAyah: nextAyahJson is Map<String, dynamic>
          ? QuranPlanNextAyah.fromJson(nextAyahJson)
          : null,
      startSurah: startS,
      startSurahName: json['startSurahName'] as String? ?? 'Al-Fatiha',
      endSurah: endS,
      endSurahName: json['endSurahName'] as String? ?? 'An-Nas',
    );
  }
}

/// Statistics calculated by the server for a Quran plan.
class QuranPlanCounts {
  const QuranPlanCounts({
    this.totalAyahs = 6236,
    this.completedAyahs = 0,
    this.remainingAyahs = 6236,
    this.percentage = 0,
    this.isCompleted = false,
    this.totalSurahs = 114,
    this.totalParas = 30,
  });

  final int totalAyahs;
  final int completedAyahs;
  final int remainingAyahs;
  final int percentage;
  final bool isCompleted;
  final int totalSurahs;
  final int totalParas;

  factory QuranPlanCounts.fromJson(Map<String, dynamic> json) =>
      QuranPlanCounts(
        totalAyahs: (json['totalAyahs'] as num?)?.toInt() ?? 6236,
        completedAyahs: (json['completedAyahs'] as num?)?.toInt() ?? 0,
        remainingAyahs: (json['remainingAyahs'] as num?)?.toInt() ?? 0,
        percentage: (json['percentage'] as num?)?.toInt() ?? 0,
        isCompleted: json['isCompleted'] as bool? ?? false,
        totalSurahs: (json['totalSurahs'] as num?)?.toInt() ?? 114,
        totalParas: (json['totalParas'] as num?)?.toInt() ?? 30,
      );

  Map<String, dynamic> toJson() => {
    'totalAyahs': totalAyahs,
    'completedAyahs': completedAyahs,
    'remainingAyahs': remainingAyahs,
    'percentage': percentage,
    'isCompleted': isCompleted,
    'totalSurahs': totalSurahs,
    'totalParas': totalParas,
  };
}

/// Schedule projection calculated by the server for a Quran plan.
class QuranPlanSchedule {
  const QuranPlanSchedule({
    this.startDate = '',
    this.endDate = '',
    this.targetDays = 30,
    this.dayNumber = 1,
    this.daysLeft = 30,
    this.ayahsPerDay = 0,
    this.expectedAyahs = 0,
    this.isOnTrack = true,
    this.aheadBy = 0,
    this.todayRemainingAyahs = 0,
    this.requiredAyahsPerDay = 0,
    this.isOverdue = false,
  });

  final String startDate;
  final String endDate;
  final int targetDays;
  final int dayNumber;
  final int daysLeft;
  final int ayahsPerDay;
  final int expectedAyahs;
  final bool isOnTrack;
  final int aheadBy;
  final int todayRemainingAyahs;
  final int requiredAyahsPerDay;
  final bool isOverdue;

  factory QuranPlanSchedule.fromJson(
    Map<String, dynamic> json,
  ) => QuranPlanSchedule(
    startDate: json['startDate'] as String? ?? '',
    endDate: json['endDate'] as String? ?? '',
    targetDays: (json['targetDays'] as num?)?.toInt() ?? 30,
    dayNumber: (json['dayNumber'] as num?)?.toInt() ?? 1,
    daysLeft: (json['daysLeft'] as num?)?.toInt() ?? 0,
    ayahsPerDay: (json['ayahsPerDay'] as num?)?.toInt() ?? 0,
    expectedAyahs: (json['expectedAyahs'] as num?)?.toInt() ?? 0,
    isOnTrack: json['isOnTrack'] as bool? ?? false,
    aheadBy: (json['aheadBy'] as num?)?.toInt() ?? 0,
    todayRemainingAyahs: (json['todayRemainingAyahs'] as num?)?.toInt() ?? 0,
    requiredAyahsPerDay: (json['requiredAyahsPerDay'] as num?)?.toInt() ?? 0,
    isOverdue: json['isOverdue'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'startDate': startDate,
    'endDate': endDate,
    'targetDays': targetDays,
    'dayNumber': dayNumber,
    'daysLeft': daysLeft,
    'ayahsPerDay': ayahsPerDay,
    'expectedAyahs': expectedAyahs,
    'isOnTrack': isOnTrack,
    'aheadBy': aheadBy,
    'todayRemainingAyahs': todayRemainingAyahs,
    'requiredAyahsPerDay': requiredAyahsPerDay,
    'isOverdue': isOverdue,
  };
}

/// Pagination metadata returned by `GET /quran/plans`.
class QuranPlanMeta {
  const QuranPlanMeta({
    this.page = 1,
    this.limit = 10,
    this.total = 0,
    this.totalPage = 0,
  });

  final int page;
  final int limit;
  final int total;
  final int totalPage;

  bool get hasMore => page < totalPage;

  factory QuranPlanMeta.fromJson(Map<String, dynamic> json) => QuranPlanMeta(
    page: (json['page'] as num?)?.toInt() ?? 1,
    limit: (json['limit'] as num?)?.toInt() ?? 10,
    total: (json['total'] as num?)?.toInt() ?? 0,
    totalPage: (json['totalPage'] as num?)?.toInt() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'page': page,
    'limit': limit,
    'total': total,
    'totalPage': totalPage,
  };
}

/// Paginated wrapper for Quran plans.
class QuranPlansResponse {
  const QuranPlansResponse({
    required this.plans,
    this.meta = const QuranPlanMeta(),
  });

  final List<QuranPlan> plans;
  final QuranPlanMeta meta;

  factory QuranPlansResponse.fromJson(Map<String, dynamic> json) {
    final list = json['data'] is List ? (json['data'] as List) : const [];
    final metaJson = json['meta'] is Map<String, dynamic>
        ? json['meta'] as Map<String, dynamic>
        : const <String, dynamic>{};
    return QuranPlansResponse(
      plans: list
          .whereType<Map<String, dynamic>>()
          .map(QuranPlan.fromJson)
          .toList(),
      meta: QuranPlanMeta.fromJson(metaJson),
    );
  }
}

/// Request body for `POST /quran/plans`.
class CreateQuranPlanRequest {
  const CreateQuranPlanRequest({
    required this.name,
    required this.targetDays,
    this.wholeQuran = true,
    this.surahNumbers = const [],
    this.paraNumbers = const [],
  });

  final String name;
  final int targetDays;
  final bool wholeQuran;
  final List<int> surahNumbers;
  final List<int> paraNumbers;

  Map<String, dynamic> toJson() => {
    'name': name,
    'wholeQuran': wholeQuran,
    'targetDays': targetDays,
    if (surahNumbers.isNotEmpty) 'surahNumbers': surahNumbers,
    if (paraNumbers.isNotEmpty) 'paraNumbers': paraNumbers,
  };
}

/// Request body for `PATCH /quran/plans/{planId}`.
class UpdateQuranPlanRequest {
  const UpdateQuranPlanRequest({
    this.status,
    this.name,
    this.description,
    this.targetDays,
    this.startDate,
    this.wholeQuran,
    this.surahNumbers,
    this.paraNumbers,
    this.isActive,
  });

  final String? status;
  final String? name;
  final String? description;
  final int? targetDays;
  final String? startDate;
  final bool? wholeQuran;
  final List<int>? surahNumbers;
  final List<int>? paraNumbers;
  final bool? isActive;

  Map<String, dynamic> toJson() => {
    if (status != null) 'status': status,
    if (name != null) 'name': name,
    if (description != null) 'description': description,
    if (targetDays != null) 'targetDays': targetDays,
    if (startDate != null) 'startDate': startDate,
    if (wholeQuran != null) 'wholeQuran': wholeQuran,
    if (surahNumbers != null) 'surahNumbers': surahNumbers,
    if (paraNumbers != null) 'paraNumbers': paraNumbers,
    if (isActive != null) 'isActive': isActive,
  };
}

/// Progress of a single Surah within a Quran plan.
class QuranPlanSurah {
  const QuranPlanSurah({
    required this.surahNumber,
    this.nameArabic = '',
    this.nameEnglish = '',
    this.nameBangla = '',
    this.totalAyahs = 0,
    this.readAyahs = 0,
    this.remainingAyahs = 0,
    this.percentage = 0,
    this.isCompleted = false,
  });

  final int surahNumber;
  final String nameArabic;
  final String nameEnglish;
  final String nameBangla;
  final int totalAyahs;
  final int readAyahs;
  final int remainingAyahs;
  final int percentage;
  final bool isCompleted;

  factory QuranPlanSurah.fromJson(Map<String, dynamic> json) => QuranPlanSurah(
    surahNumber: (json['surahNumber'] as num?)?.toInt() ?? 0,
    nameArabic: json['nameArabic'] as String? ?? '',
    nameEnglish: json['nameEnglish'] as String? ?? '',
    nameBangla: json['nameBangla'] as String? ?? '',
    totalAyahs: (json['totalAyahs'] as num?)?.toInt() ?? 0,
    readAyahs: (json['readAyahs'] as num?)?.toInt() ?? 0,
    remainingAyahs: (json['remainingAyahs'] as num?)?.toInt() ?? 0,
    percentage: (json['percentage'] as num?)?.toInt() ?? 0,
    isCompleted: json['isCompleted'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'surahNumber': surahNumber,
    'nameArabic': nameArabic,
    'nameEnglish': nameEnglish,
    'nameBangla': nameBangla,
    'totalAyahs': totalAyahs,
    'readAyahs': readAyahs,
    'remainingAyahs': remainingAyahs,
    'percentage': percentage,
    'isCompleted': isCompleted,
  };
}

/// Progress of a single Para within a Quran plan.
class QuranPlanPara {
  const QuranPlanPara({
    required this.paraNumber,
    this.nameBangla = '',
    this.nameEnglish = '',
    this.nameArabic = '',
    this.totalAyahs = 0,
    this.readAyahs = 0,
    this.remainingAyahs = 0,
    this.percentage = 0,
    this.isCompleted = false,
    this.start,
    this.end,
  });

  final int paraNumber;
  final String nameBangla;
  final String nameEnglish;
  final String nameArabic;
  final int totalAyahs;
  final int readAyahs;
  final int remainingAyahs;
  final int percentage;
  final bool isCompleted;
  final Map<String, dynamic>? start;
  final Map<String, dynamic>? end;

  factory QuranPlanPara.fromJson(Map<String, dynamic> json) => QuranPlanPara(
    paraNumber: (json['paraNumber'] as num?)?.toInt() ?? 0,
    nameBangla: json['nameBangla'] as String? ?? '',
    nameEnglish: json['nameEnglish'] as String? ?? '',
    nameArabic: json['nameArabic'] as String? ?? '',
    totalAyahs: (json['totalAyahs'] as num?)?.toInt() ?? 0,
    readAyahs: (json['readAyahs'] as num?)?.toInt() ?? 0,
    remainingAyahs: (json['remainingAyahs'] as num?)?.toInt() ?? 0,
    percentage: (json['percentage'] as num?)?.toInt() ?? 0,
    isCompleted: json['isCompleted'] as bool? ?? false,
    start: json['start'] as Map<String, dynamic>?,
    end: json['end'] as Map<String, dynamic>?,
  );

  Map<String, dynamic> toJson() => {
    'paraNumber': paraNumber,
    'nameBangla': nameBangla,
    if (nameEnglish.isNotEmpty) 'nameEnglish': nameEnglish,
    if (nameArabic.isNotEmpty) 'nameArabic': nameArabic,
    'totalAyahs': totalAyahs,
    'readAyahs': readAyahs,
    'remainingAyahs': remainingAyahs,
    'percentage': percentage,
    'isCompleted': isCompleted,
    if (start != null) 'start': start,
    if (end != null) 'end': end,
  };
}

/// The next unread Ayah for continuing reading.
class QuranPlanNextAyah {
  const QuranPlanNextAyah({
    required this.surahNumber,
    required this.ayahNumber,
    required this.ayahKey,
    this.paraNumber = 1,
    this.surahNameEnglish = '',
    this.surahNameBangla = '',
    this.surahNameArabic = '',
  });

  final int surahNumber;
  final int ayahNumber;
  final String ayahKey;
  final int paraNumber;
  final String surahNameEnglish;
  final String surahNameBangla;
  final String surahNameArabic;

  factory QuranPlanNextAyah.fromJson(Map<String, dynamic> json) =>
      QuranPlanNextAyah(
        surahNumber: (json['surahNumber'] as num?)?.toInt() ?? 0,
        ayahNumber: (json['ayahNumber'] as num?)?.toInt() ?? 0,
        ayahKey: json['ayahKey'] as String? ?? '',
        paraNumber: (json['paraNumber'] as num?)?.toInt() ?? 1,
        surahNameEnglish: json['surahNameEnglish'] as String? ?? '',
        surahNameBangla: json['surahNameBangla'] as String? ?? '',
        surahNameArabic: json['surahNameArabic'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
    'surahNumber': surahNumber,
    'ayahNumber': ayahNumber,
    'ayahKey': ayahKey,
    'paraNumber': paraNumber,
    'surahNameEnglish': surahNameEnglish,
    'surahNameBangla': surahNameBangla,
    'surahNameArabic': surahNameArabic,
  };
}

/// A single Ayah item from `GET /quran/plans/{planId}/ayahs`.
class QuranPlanAyah {
  const QuranPlanAyah({
    required this.surahNumber,
    required this.ayahNumber,
    required this.ayahKey,
    this.paraNumber = 1,
    this.surahNameEnglish = '',
    this.surahNameBangla = '',
    this.surahNameArabic = '',
    this.isRead = false,
  });

  final int surahNumber;
  final int ayahNumber;
  final String ayahKey;
  final int paraNumber;
  final String surahNameEnglish;
  final String surahNameBangla;
  final String surahNameArabic;
  final bool isRead;

  factory QuranPlanAyah.fromJson(Map<String, dynamic> json) => QuranPlanAyah(
    surahNumber: (json['surahNumber'] as num?)?.toInt() ?? 0,
    ayahNumber: (json['ayahNumber'] as num?)?.toInt() ?? 0,
    ayahKey: json['ayahKey'] as String? ?? '',
    paraNumber: (json['paraNumber'] as num?)?.toInt() ?? 1,
    surahNameEnglish: json['surahNameEnglish'] as String? ?? '',
    surahNameBangla: json['surahNameBangla'] as String? ?? '',
    surahNameArabic: json['surahNameArabic'] as String? ?? '',
    isRead: json['isRead'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'surahNumber': surahNumber,
    'ayahNumber': ayahNumber,
    'ayahKey': ayahKey,
    'paraNumber': paraNumber,
    'surahNameEnglish': surahNameEnglish,
    'surahNameBangla': surahNameBangla,
    'surahNameArabic': surahNameArabic,
    'isRead': isRead,
  };
}

/// Paginated result of `GET /quran/plans/{planId}/ayahs`.
class PaginatedQuranPlanAyahs {
  const PaginatedQuranPlanAyahs({
    required this.ayahs,
    this.meta = const QuranPlanMeta(),
  });

  final List<QuranPlanAyah> ayahs;
  final QuranPlanMeta meta;

  factory PaginatedQuranPlanAyahs.fromJson(Map<String, dynamic> json) {
    final list = json['data'] is List ? (json['data'] as List) : const [];
    final metaJson = json['meta'] is Map<String, dynamic>
        ? json['meta'] as Map<String, dynamic>
        : const <String, dynamic>{};
    return PaginatedQuranPlanAyahs(
      ayahs: list
          .whereType<Map<String, dynamic>>()
          .map(QuranPlanAyah.fromJson)
          .toList(),
      meta: QuranPlanMeta.fromJson(metaJson),
    );
  }
}
