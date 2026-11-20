import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/features/dua/data/models/dua_api_models.dart';

int duaApiInt(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;

double duaApiDouble(Object? value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

bool duaApiBool(Object? value) =>
    value == true || value == 1 || value == 'true';

Map<String, dynamic> duaApiMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};

String duaApiId(Map<String, dynamic> json) =>
    readId(json['_id']) ?? readId(json['id']) ?? '';

/// One entry returned by the reading-history and dashboard endpoints. The
/// server has used both nested (`dua`, `category`) and flattened responses,
/// therefore this parser deliberately accepts both without inventing values.
class DuaReadingHistoryItem {
  const DuaReadingHistoryItem({
    required this.duaId,
    required this.title,
    required this.arabic,
    required this.category,
    this.readCount = 0,
    this.readSeconds = 0,
    this.lastReadAt,
    this.timeAgoText = '',
  });

  final String duaId;
  final LocalizedText title;
  final String arabic;
  final LocalizedText category;
  final int readCount;
  final int readSeconds;
  final DateTime? lastReadAt;
  final String timeAgoText;

  factory DuaReadingHistoryItem.fromJson(Map<String, dynamic> json) {
    final dua = duaApiMap(json['dua']);
    final category = duaApiMap(json['category']).isNotEmpty
        ? duaApiMap(json['category'])
        : duaApiMap(dua['category']);
    final title = json['title'] ?? dua['title'];
    return DuaReadingHistoryItem(
      duaId: readId(json['duaId']) ?? readId(dua['_id']) ?? duaApiId(json),
      title: LocalizedText.fromJson(title),
      arabic: (json['arabic'] ?? dua['arabic'] ?? '').toString(),
      category: LocalizedText.fromJson(
        category['name'] ?? json['categoryName'],
      ),
      readCount: duaApiInt(json['readCount'] ?? json['count']),
      readSeconds: duaApiInt(json['readSeconds'] ?? json['seconds']),
      lastReadAt: DateTime.tryParse(
        (json['lastReadAt'] ?? json['readAt'] ?? json['createdAt'] ?? '')
            .toString(),
      ),
      timeAgoText: json['timeAgoText']?.toString() ?? '',
    );
  }
}

class DuaReadingHistoryPage {
  const DuaReadingHistoryPage({
    required this.items,
    required this.page,
    required this.totalPage,
  });

  final List<DuaReadingHistoryItem> items;
  final int page;
  final int totalPage;
  bool get hasMore => page < totalPage;
}

class DuaDailySummary {
  const DuaDailySummary({
    required this.date,
    required this.readSeconds,
    required this.readMinutes,
    required this.points,
    required this.maxPoints,
    required this.duasReadCount,
    required this.recitedDuas,
    this.pointsText = '',
    this.progressText = '',
    this.isGoalMet = false,
    this.planProgress,
  });

  final String date;
  final int readSeconds;
  final int readMinutes;
  final double points;
  final double maxPoints;
  final int duasReadCount;
  final List<DuaReadingHistoryItem> recitedDuas;
  final String pointsText;
  final String progressText;
  final bool isGoalMet;
  final DuaPlanProgress? planProgress;

  factory DuaDailySummary.fromJson(Map<String, dynamic> json) =>
      DuaDailySummary(
        date: json['date']?.toString() ?? '',
        readSeconds: duaApiInt(json['readSeconds']),
        readMinutes: duaApiInt(json['readMinutes']),
        points: duaApiDouble(json['points']),
        maxPoints: duaApiDouble(json['maxPoints']),
        duasReadCount: duaApiInt(json['duasReadCount']),
        recitedDuas: [
          for (final item in json['recitedDuas'] as List? ?? const [])
            if (item is Map)
              DuaReadingHistoryItem.fromJson(Map<String, dynamic>.from(item)),
        ],
        pointsText: json['pointsText']?.toString() ?? '',
        progressText: json['progressText']?.toString() ?? '',
        isGoalMet: duaApiBool(json['isGoalMet']),
        planProgress: json['planProgress'] is Map
            ? DuaPlanProgress.fromJson(
                Map<String, dynamic>.from(json['planProgress'] as Map),
              )
            : null,
      );
}

class DuaPlanProgress {
  const DuaPlanProgress({
    required this.totalDuasTarget,
    required this.completedDuas,
    required this.isAllCompleted,
  });

  final int totalDuasTarget;
  final int completedDuas;
  final bool isAllCompleted;

  factory DuaPlanProgress.fromJson(Map<String, dynamic> json) =>
      DuaPlanProgress(
        totalDuasTarget: duaApiInt(json['totalDuasTarget']),
        completedDuas: duaApiInt(json['completedDuas']),
        isAllCompleted: duaApiBool(json['isAllCompleted']),
      );
}

class DuaCalendarDay {
  const DuaCalendarDay({
    required this.date,
    required this.dayOfMonth,
    required this.hasActivity,
    required this.isGoalMet,
    required this.readMinutes,
  });

  final String date;
  final int dayOfMonth;
  final bool hasActivity;
  final bool isGoalMet;
  final int readMinutes;

  factory DuaCalendarDay.fromJson(Map<String, dynamic> json) => DuaCalendarDay(
    date: json['date']?.toString() ?? '',
    dayOfMonth: duaApiInt(json['dayOfMonth']),
    hasActivity: duaApiBool(json['hasActivity']),
    isGoalMet: duaApiBool(json['isGoalMet']),
    readMinutes: duaApiInt(json['readMinutes']),
  );
}

class DuaReadingCalendar {
  const DuaReadingCalendar({
    required this.from,
    required this.to,
    required this.days,
    required this.currentStreak,
  });

  final String from;
  final String to;
  final List<DuaCalendarDay> days;
  final int currentStreak;

  factory DuaReadingCalendar.fromJson(Map<String, dynamic> json) {
    final totals = duaApiMap(json['totals']);
    return DuaReadingCalendar(
      from: json['from']?.toString() ?? '',
      to: json['to']?.toString() ?? '',
      days: [
        for (final item in json['days'] as List? ?? const [])
          if (item is Map)
            DuaCalendarDay.fromJson(Map<String, dynamic>.from(item)),
      ],
      currentStreak: duaApiInt(totals['currentStreak']),
    );
  }
}

class DuaReadingDashboard {
  const DuaReadingDashboard({
    required this.timeframe,
    required this.totalDuasRecited,
    required this.dailyTargetText,
    required this.totalReadingTimeFormatted,
    required this.myPositionPercentage,
    required this.competitorPercentage,
    required this.recentRecitations,
    required this.activity,
  });

  final String timeframe;
  final int totalDuasRecited;
  final String dailyTargetText;
  final String totalReadingTimeFormatted;
  final double myPositionPercentage;
  final double competitorPercentage;
  final List<DuaReadingHistoryItem> recentRecitations;
  final List<DuaDashboardActivityDay> activity;

  factory DuaReadingDashboard.fromJson(Map<String, dynamic> json) {
    final overview = duaApiMap(json['overview']);
    final weekly = duaApiMap(json['weeklyActivity']);
    return DuaReadingDashboard(
      timeframe: json['timeframe']?.toString() ?? 'daily',
      totalDuasRecited: duaApiInt(overview['totalDuasRecited']),
      dailyTargetText: overview['dailyTargetText']?.toString() ?? '',
      totalReadingTimeFormatted:
          overview['totalReadingTimeFormatted']?.toString() ?? '',
      myPositionPercentage: duaApiDouble(overview['myPositionPercentage']),
      competitorPercentage: duaApiDouble(overview['competitorPercentage']),
      recentRecitations: [
        for (final item in json['recentRecitations'] as List? ?? const [])
          if (item is Map)
            DuaReadingHistoryItem.fromJson(Map<String, dynamic>.from(item)),
      ],
      activity: [
        for (final item in weekly['days'] as List? ?? const [])
          if (item is Map)
            DuaDashboardActivityDay.fromJson(Map<String, dynamic>.from(item)),
      ],
    );
  }
}

class DuaDashboardActivityDay {
  const DuaDashboardActivityDay({
    required this.label,
    required this.minutes,
    required this.duas,
  });
  final String label;
  final int minutes;
  final int duas;
  factory DuaDashboardActivityDay.fromJson(Map<String, dynamic> json) =>
      DuaDashboardActivityDay(
        label: json['dayOfWeek']?.toString() ?? '',
        minutes: duaApiInt(json['readMinutes']),
        duas: duaApiInt(json['duasCount']),
      );
}

class DuaPlanHistory {
  const DuaPlanHistory({
    required this.planId,
    required this.currentStreak,
    required this.longestStreak,
    required this.completedDays,
    required this.scheduledDays,
    required this.completionRate,
    required this.days,
  });
  final String planId;
  final int currentStreak;
  final int longestStreak;
  final int completedDays;
  final int scheduledDays;
  final double completionRate;
  final List<DuaPlanHistoryDay> days;
  factory DuaPlanHistory.fromJson(Map<String, dynamic> json) => DuaPlanHistory(
    planId: readId(json['planId']) ?? '',
    currentStreak: duaApiInt(json['currentStreak']),
    longestStreak: duaApiInt(json['longestStreak']),
    completedDays: duaApiInt(json['completedDays']),
    scheduledDays: duaApiInt(json['scheduledDays']),
    completionRate: duaApiDouble(json['completionRate']),
    days: [
      for (final item in json['days'] as List? ?? const [])
        if (item is Map)
          DuaPlanHistoryDay.fromJson(Map<String, dynamic>.from(item)),
    ],
  );
}

class DuaPlanHistoryDay {
  const DuaPlanHistoryDay({
    required this.date,
    required this.completedDuas,
    required this.totalDuas,
    required this.isCompleted,
    required this.isScheduled,
    required this.isFuture,
  });
  final String date;
  final int completedDuas;
  final int totalDuas;
  final bool isCompleted;
  final bool isScheduled;
  final bool isFuture;
  factory DuaPlanHistoryDay.fromJson(Map<String, dynamic> json) =>
      DuaPlanHistoryDay(
        date: json['date']?.toString() ?? '',
        completedDuas: duaApiInt(json['completedDuas']),
        totalDuas: duaApiInt(json['totalDuas']),
        isCompleted: duaApiBool(json['isCompleted']),
        isScheduled: duaApiBool(json['isScheduled']),
        isFuture: duaApiBool(json['isFuture']),
      );
}

/// The planner-today response is kept as its server-provided summary and
/// groups. The app can render any routine shape without deriving completion
/// from local counters.
class DuaPlannerToday {
  const DuaPlannerToday({
    required this.totalDuas,
    required this.completedDuas,
    required this.percentage,
    required this.groups,
  });
  final int totalDuas;
  final int completedDuas;
  final double percentage;
  final List<Map<String, dynamic>> groups;
  factory DuaPlannerToday.fromJson(Map<String, dynamic> json) =>
      DuaPlannerToday(
        totalDuas: duaApiInt(json['totalDuas'] ?? json['totalDuasTarget']),
        completedDuas: duaApiInt(json['completedDuas']),
        percentage: duaApiDouble(json['percentage']),
        groups: [
          for (final value
              in (json['plans'] ?? json['groups'] ?? json['items']) as List? ??
                  const [])
            if (value is Map) Map<String, dynamic>.from(value),
        ],
      );
}
