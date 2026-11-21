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
    // `category` arrives three ways: a populated object (`{name: {...}}`),
    // a bilingual map, or — as the dashboard sends it — a plain string
    // ("Daily Adhkar"). All three have to resolve to the same label.
    final rawCategory =
        json['category'] ?? dua['category'] ?? json['categoryName'];
    final title = json['title'] ?? dua['title'];
    return DuaReadingHistoryItem(
      duaId: readId(json['duaId']) ?? readId(dua['_id']) ?? duaApiId(json),
      title: LocalizedText.fromJson(title),
      arabic: (json['arabic'] ?? dua['arabic'] ?? '').toString(),
      category: LocalizedText.fromJson(
        rawCategory is Map ? (rawCategory['name'] ?? rawCategory) : rawCategory,
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

/// Minutes read, from the server's own formatted string (`1h 14m`,
/// `23 min`, `42 min`).
///
/// The 3-tier comparison carries each side's time only as that text, so the
/// bars have no other numeric source to be drawn against.
int duaParseReadingMinutes(String formatted) {
  if (formatted.trim().isEmpty) return 0;
  final hours = RegExp(r'(\d+)\s*h').firstMatch(formatted);
  final minutes = RegExp(r'(\d+)\s*m').firstMatch(formatted);
  if (hours == null && minutes == null) {
    return int.tryParse(formatted.trim()) ?? 0;
  }
  return int.parse(hours?.group(1) ?? '0') * 60 +
      int.parse(minutes?.group(1) ?? '0');
}

/// One side of the dashboard's 3-tier comparison — `me`, `rival` or
/// `topLeader` — as the overview, a weekly day or a monthly period carries
/// it.
class DuaComparisonSide {
  const DuaComparisonSide({
    required this.name,
    required this.readingTimeFormatted,
    required this.pointsText,
    this.rank = 0,
    this.percentage = 0,
    this.duasCount = 0,
    this.pointsDifference = 0,
  });

  final String name;

  /// `1h 14m` / `23 min`, shown verbatim.
  final String readingTimeFormatted;

  /// Already prefixed by the server (`Point : 6/10`), so it is never
  /// labelled again in the UI.
  final String pointsText;
  final int rank;
  final double percentage;
  final int duasCount;

  /// How far ahead of (or behind) the user this side is; `rival` only.
  final int pointsDifference;

  /// [readingTimeFormatted] as a number, for the bar's length.
  int get readingMinutes => duaParseReadingMinutes(readingTimeFormatted);

  static DuaComparisonSide? fromJson(Object? json) {
    if (json is! Map) return null;
    final map = Map<String, dynamic>.from(json);
    final side = DuaComparisonSide(
      name: map['name']?.toString() ?? '',
      readingTimeFormatted: map['readingTimeFormatted']?.toString() ?? '',
      pointsText: map['pointsText']?.toString() ?? '',
      rank: duaApiInt(map['rank']),
      percentage: duaApiDouble(map['percentage']),
      duasCount: duaApiInt(map['duasCount']),
      pointsDifference: duaApiInt(map['pointsDifference']),
    );
    // An empty object says nothing; treat it as absent rather than as a
    // nameless participant with no time.
    return side.name.isEmpty &&
            side.readingTimeFormatted.isEmpty &&
            side.pointsText.isEmpty
        ? null
        : side;
  }
}

/// `me` / `rival` / `topLeader` together, as `overview.comparison` and each
/// activity entry carry them.
class DuaComparison {
  const DuaComparison({this.me, this.rival, this.topLeader});

  final DuaComparisonSide? me;

  /// The nearest competitor — the side the two-colour charts are drawn
  /// against.
  final DuaComparisonSide? rival;

  /// The leader of the whole board; parsed and available, though the charts
  /// only have two colours to spend.
  final DuaComparisonSide? topLeader;

  bool get isEmpty => me == null && rival == null && topLeader == null;

  factory DuaComparison.fromJson(Object? json) {
    final map = duaApiMap(json);
    return DuaComparison(
      // `overview.comparison` calls the user's own side `me`, while a
      // weekly day and a monthly period call it `my`.
      me: DuaComparisonSide.fromJson(map['me'] ?? map['my']),
      rival: DuaComparisonSide.fromJson(map['rival']),
      topLeader: DuaComparisonSide.fromJson(map['topLeader']),
    );
  }
}

/// One row of `monthlyActivity.periods[]` — a span of the month the server
/// has already labelled (`1-6`, `7-13`, …).
class DuaDashboardPeriod {
  const DuaDashboardPeriod({
    required this.label,
    required this.comparison,
    this.minutes = 0,
  });

  final String label;
  final DuaComparison comparison;

  /// The user's own minutes: `readMinutes` when the server sends it, else
  /// `my.readingTimeFormatted` read as a number.
  final int minutes;

  factory DuaDashboardPeriod.fromJson(Map<String, dynamic> json) {
    final comparison = DuaComparison.fromJson(json);
    return DuaDashboardPeriod(
      label: json['label']?.toString() ?? '',
      comparison: comparison,
      minutes: json['readMinutes'] != null
          ? duaApiInt(json['readMinutes'])
          : comparison.me?.readingMinutes ?? 0,
    );
  }
}

class DuaReadingDashboard {
  const DuaReadingDashboard({
    required this.timeframe,
    required this.date,
    required this.totalDuasRecited,
    required this.dailyTargetText,
    required this.totalReadingTimeSeconds,
    required this.totalReadingTimeFormatted,
    required this.myPositionPercentage,
    required this.competitorPercentage,
    required this.recentRecitations,
    required this.activity,
    required this.activityFrom,
    required this.activityTo,
    this.today,
    this.comparison = const DuaComparison(),
    this.periods = const [],
  });

  /// `daily` | `weekly` | `monthly` — what the server answered for, which
  /// may differ from what was asked when the parameter was dropped.
  final String timeframe;

  /// The day the window is anchored on (`YYYY-MM-DD`).
  final String date;
  final int totalDuasRecited;

  /// A fraction the server formats itself ("35/40"); shown verbatim.
  final String dailyTargetText;
  final int totalReadingTimeSeconds;
  final String totalReadingTimeFormatted;
  final double myPositionPercentage;
  final double competitorPercentage;
  final List<DuaReadingHistoryItem> recentRecitations;

  /// `weeklyActivity.days` — one entry per day of the returned window, which
  /// is a week for `daily`/`weekly` and a month for `monthly`.
  final List<DuaDashboardActivityDay> activity;
  final String activityFrom;
  final String activityTo;

  /// Today's own totals, sent alongside the window's. Absent on responses
  /// that omit the `today` block.
  final DuaDashboardToday? today;

  /// `overview.comparison` — the window's 3-tier standing. Empty on a
  /// response from before the comparison model was added.
  final DuaComparison comparison;

  /// `monthlyActivity.periods[]`, the month's own already-labelled spans.
  /// Empty when the server sends only [activity].
  final List<DuaDashboardPeriod> periods;

  factory DuaReadingDashboard.fromJson(Map<String, dynamic> json) {
    final overview = duaApiMap(json['overview']);
    final weekly = duaApiMap(json['weeklyActivity']).isNotEmpty
        ? duaApiMap(json['weeklyActivity'])
        : duaApiMap(json['activity']);
    final today = json['today'];
    return DuaReadingDashboard(
      timeframe: json['timeframe']?.toString() ?? 'daily',
      date: json['date']?.toString() ?? '',
      totalDuasRecited: duaApiInt(overview['totalDuasRecited']),
      dailyTargetText: overview['dailyTargetText']?.toString() ?? '',
      totalReadingTimeSeconds: duaApiInt(overview['totalReadingTimeSeconds']),
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
      activityFrom: weekly['from']?.toString() ?? '',
      activityTo: weekly['to']?.toString() ?? '',
      today: today is Map
          ? DuaDashboardToday.fromJson(Map<String, dynamic>.from(today))
          : null,
      comparison: DuaComparison.fromJson(overview['comparison']),
      periods: [
        for (final item
            in duaApiMap(json['monthlyActivity'])['periods'] as List? ??
                const [])
          if (item is Map)
            DuaDashboardPeriod.fromJson(Map<String, dynamic>.from(item)),
      ],
    );
  }
}

/// The `today` block of the reading dashboard.
class DuaDashboardToday {
  const DuaDashboardToday({
    required this.duasReadCount,
    required this.readMinutes,
    required this.isGoalMet,
  });

  final int duasReadCount;
  final int readMinutes;
  final bool isGoalMet;

  factory DuaDashboardToday.fromJson(Map<String, dynamic> json) =>
      DuaDashboardToday(
        duasReadCount: duaApiInt(json['duasReadCount']),
        readMinutes: duaApiInt(json['readMinutes']),
        isGoalMet: duaApiBool(json['isGoalMet']),
      );
}

class DuaDashboardActivityDay {
  const DuaDashboardActivityDay({
    required this.label,
    required this.date,
    required this.minutes,
    required this.duas,
    this.comparison = const DuaComparison(),
  });

  /// `Sat`, `Sun`, ... as the server writes it.
  final String label;

  /// `YYYY-MM-DD`; empty when the server omits it.
  final String date;
  final int minutes;
  final int duas;

  /// This day's own `me` / `rival` / `topLeader`.
  final DuaComparison comparison;

  /// The day of the month, used to bucket a month's days into its weeks.
  /// `0` when [date] is missing or unparseable.
  int get dayOfMonth => DateTime.tryParse(date)?.day ?? 0;

  factory DuaDashboardActivityDay.fromJson(Map<String, dynamic> json) {
    final comparison = DuaComparison.fromJson(json);
    return DuaDashboardActivityDay(
      label: json['dayOfWeek']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      minutes: json['readMinutes'] != null
          ? duaApiInt(json['readMinutes'])
          : comparison.me?.readingMinutes ?? 0,
      // `duasCount` moved inside `my` with the comparison model; the older
      // top-level field still counts when it is the only one sent.
      duas: duaApiInt(json['duasCount']) != 0
          ? duaApiInt(json['duasCount'])
          : comparison.me?.duasCount ?? 0,
      comparison: comparison,
    );
  }
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
