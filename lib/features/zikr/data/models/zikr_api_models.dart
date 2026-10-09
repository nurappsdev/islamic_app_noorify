class ApiErrorResponse {
  const ApiErrorResponse({
    required this.statusCode,
    required this.message,
    required this.errorSources,
  });

  final int statusCode;
  final String message;
  final List<ApiErrorSource> errorSources;

  factory ApiErrorResponse.fromJson(Map<String, dynamic> json) =>
      ApiErrorResponse(
        statusCode: _asInt(json['statusCode']) ?? 500,
        message: json['message']?.toString() ?? 'Unknown error',
        errorSources: [
          for (final source in json['errorSources'] as List? ?? const [])
            if (source is Map)
              ApiErrorSource.fromJson(Map<String, dynamic>.from(source)),
        ],
      );
}

class ApiErrorSource {
  const ApiErrorSource({required this.path, required this.message});

  final String path;
  final String message;

  factory ApiErrorSource.fromJson(Map<String, dynamic> json) => ApiErrorSource(
    path: json['path']?.toString() ?? '',
    message: json['message']?.toString() ?? '',
  );
}

class ZikrCatalogItem {
  const ZikrCatalogItem({
    required this.id,
    required this.zikrName,
    required this.nameArabic,
    required this.nameTransliteration,
    required this.defaultTargetCount,
    this.displayOrder,
  });

  final String id;
  final String zikrName;
  final String nameArabic;
  final String nameTransliteration;
  final int defaultTargetCount;
  final int? displayOrder;

  factory ZikrCatalogItem.fromJson(Map<String, dynamic> json) =>
      ZikrCatalogItem(
        id: _idOf(json),
        zikrName: json['zikrName']?.toString() ?? '',
        nameArabic: json['nameArabic']?.toString() ?? '',
        nameTransliteration: json['nameTransliteration']?.toString() ?? '',
        defaultTargetCount: _asInt(json['defaultTargetCount']) ?? 33,
        displayOrder: _asInt(json['displayOrder']),
      );
}

class ZikrRoutineItem {
  const ZikrRoutineItem({
    required this.zikrKey,
    required this.zikrName,
    required this.nameArabic,
    required this.targetCount,
  });

  final String zikrKey;
  final String zikrName;
  final String nameArabic;
  final int targetCount;

  factory ZikrRoutineItem.fromJson(Map<String, dynamic> json) =>
      ZikrRoutineItem(
        zikrKey: json['zikrKey']?.toString() ?? _zikrKey(json['zikrName']),
        zikrName: json['zikrName']?.toString() ?? '',
        nameArabic: json['nameArabic']?.toString() ?? '',
        targetCount: _asInt(json['targetCount']) ?? 1,
      );

  Map<String, dynamic> toJson() => {
    'zikrKey': zikrKey,
    'zikrName': zikrName,
    if (nameArabic.isNotEmpty) 'nameArabic': nameArabic,
    'targetCount': targetCount,
  };
}

class ZikrRoutine {
  const ZikrRoutine({
    required this.id,
    required this.routineName,
    required this.description,
    required this.totalTargetCount,
    required this.isPreset,
    required this.items,
  });

  final String id;
  final String routineName;
  final String description;
  final int totalTargetCount;
  final bool isPreset;
  final List<ZikrRoutineItem> items;

  factory ZikrRoutine.fromJson(Map<String, dynamic> json) => ZikrRoutine(
    id: _idOf(json),
    routineName: json['routineName']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    totalTargetCount: _asInt(json['totalTargetCount']) ?? 0,
    isPreset: json['isPreset'] == true,
    items: _itemsOf(json),
  );
}

class ZikrPlan {
  const ZikrPlan({
    required this.id,
    required this.planName,
    required this.completionDays,
    required this.totalTargetCount,
    required this.currentCount,
    required this.status,
    required this.isPreset,
    required this.items,
    this.startDate,
    this.targetEndDate,
    this.completedAt,
  });

  final String id;
  final String planName;
  final int completionDays;
  final int totalTargetCount;
  final int currentCount;
  final String status;
  final bool isPreset;
  final List<ZikrRoutineItem> items;
  final DateTime? startDate;
  final DateTime? targetEndDate;
  final DateTime? completedAt;

  bool get completed => status == 'completed';

  factory ZikrPlan.fromJson(Map<String, dynamic> json) => ZikrPlan(
    id: _idOf(json),
    planName: json['planName']?.toString() ?? '',
    completionDays: _asInt(json['completionDays']) ?? 1,
    totalTargetCount: _asInt(json['totalTargetCount']) ?? 0,
    currentCount: _asInt(json['currentCount']) ?? 0,
    status: json['status']?.toString() ?? 'active',
    isPreset: json['isPreset'] == true,
    items: _itemsOf(json),
    startDate: _dateOf(json['startDate']),
    targetEndDate: _dateOf(json['targetEndDate']),
    completedAt: _dateOf(json['completedAt']),
  );
}

class UserTasbihProfile {
  const UserTasbihProfile({
    required this.lifetimeTotalCount,
    required this.mostPerformedZikrKey,
    required this.mostPerformedZikrName,
    required this.mostPerformedCount,
  });

  final int lifetimeTotalCount;
  final String mostPerformedZikrKey;
  final String mostPerformedZikrName;
  final int mostPerformedCount;

  factory UserTasbihProfile.fromJson(Map<String, dynamic> json) =>
      UserTasbihProfile(
        lifetimeTotalCount: _asInt(json['lifetimeTotalCount']) ?? 0,
        mostPerformedZikrKey: json['mostPerformedZikrKey']?.toString() ?? '',
        mostPerformedZikrName: json['mostPerformedZikrName']?.toString() ?? '',
        mostPerformedCount: _asInt(json['mostPerformedCount']) ?? 0,
      );
}

class TasbihChartPoint {
  const TasbihChartPoint({
    required this.label,
    required this.myPosition,
    required this.competitor,
  });

  final String label;
  final double myPosition;
  final double competitor;

  factory TasbihChartPoint.fromJson(Map<String, dynamic> json) =>
      TasbihChartPoint(
        label: json['label']?.toString() ?? '',
        myPosition: _asDouble(json['myPosition']),
        competitor: _asDouble(json['competitor']),
      );
}

class ZikrSessionHistory {
  const ZikrSessionHistory({
    required this.id,
    required this.zikrKey,
    required this.zikrName,
    required this.nameArabic,
    required this.countAdded,
    required this.sessionDate,
    this.createdAt,
  });

  final String id;
  final String zikrKey;
  final String zikrName;
  final String nameArabic;
  final int countAdded;
  final String sessionDate;
  final DateTime? createdAt;

  factory ZikrSessionHistory.fromJson(Map<String, dynamic> json) =>
      ZikrSessionHistory(
        id: _idOf(json),
        zikrKey: json['zikrKey']?.toString() ?? _zikrKey(json['zikrName']),
        zikrName: json['zikrName']?.toString() ?? '',
        nameArabic: json['nameArabic']?.toString() ?? '',
        countAdded: _asInt(json['countAdded']) ?? 0,
        sessionDate: json['sessionDate']?.toString() ?? '',
        createdAt: _dateOf(json['createdAt']),
      );
}

class PaginationMeta {
  const PaginationMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPage,
  });

  final int page;
  final int limit;
  final int total;
  final int totalPage;

  factory PaginationMeta.fromJson(Map<String, dynamic> json) => PaginationMeta(
    page: _asInt(json['page']) ?? 1,
    limit: _asInt(json['limit']) ?? 20,
    total: _asInt(json['total']) ?? 0,
    totalPage: _asInt(json['totalPage']) ?? 1,
  );
}

class PaginatedHistory {
  const PaginatedHistory({required this.items, required this.meta});
  final List<ZikrSessionHistory> items;
  final PaginationMeta meta;
}

class TasbihAnalyticsResponse {
  const TasbihAnalyticsResponse({
    required this.period,
    required this.userTotalZikr,
    required this.competitorTotalZikr,
    required this.competitorName,
    required this.lifetimeTotalCount,
    required this.mostDoingZikrName,
    required this.mostDoingZikrCount,
    required this.chartData,
    required this.recentHistory,
  });

  final String period;
  final int userTotalZikr;
  final int competitorTotalZikr;
  final String competitorName;
  final int lifetimeTotalCount;
  final String mostDoingZikrName;
  final int mostDoingZikrCount;
  final List<TasbihChartPoint> chartData;
  final List<ZikrSessionHistory> recentHistory;

  factory TasbihAnalyticsResponse.fromJson(Map<String, dynamic> json) =>
      TasbihAnalyticsResponse(
        period: json['period']?.toString() ?? 'daily',
        userTotalZikr: _asInt(json['userTotalZikr']) ?? 0,
        competitorTotalZikr: _asInt(json['competitorTotalZikr']) ?? 0,
        competitorName: json['competitorName']?.toString() ?? '',
        lifetimeTotalCount: _asInt(json['lifetimeTotalCount']) ?? 0,
        mostDoingZikrName: json['mostDoingZikrName']?.toString() ?? '',
        mostDoingZikrCount: _asInt(json['mostDoingZikrCount']) ?? 0,
        chartData: [
          for (final point in json['chartData'] as List? ?? const [])
            if (point is Map)
              TasbihChartPoint.fromJson(Map<String, dynamic>.from(point)),
        ],
        recentHistory: [
          for (final item in json['recentHistory'] as List? ?? const [])
            if (item is Map)
              ZikrSessionHistory.fromJson(Map<String, dynamic>.from(item)),
        ],
      );
}

int? _asInt(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value');
double _asDouble(Object? value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
String _idOf(Map<String, dynamic> json) =>
    json['_id']?.toString() ?? json['id']?.toString() ?? '';
DateTime? _dateOf(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
String _zikrKey(Object? value) =>
    value
        ?.toString()
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '') ??
    'general';
List<ZikrRoutineItem> _itemsOf(Map<String, dynamic> json) => [
  for (final item in json['items'] as List? ?? const [])
    if (item is Map) ZikrRoutineItem.fromJson(Map<String, dynamic>.from(item)),
];
