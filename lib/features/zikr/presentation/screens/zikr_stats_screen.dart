import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/utils/app_color.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:tuhfatul_muslim/features/zikr/presentation/widgets/zikr_bottom_nav.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/core/localization/localization_context.dart';
import 'package:tuhfatul_muslim/features/zikr/data/models/zikr_api_models.dart';
import 'package:tuhfatul_muslim/features/zikr/presentation/bloc/zikr_analytics_cubit.dart';
import 'package:tuhfatul_muslim/features/zikr/presentation/zikr_localized_name.dart';
import 'package:tuhfatul_muslim/features/zikr/presentation/zikr_login_dialog.dart';
import 'package:tuhfatul_muslim/features/zikr/zikr_dependencies.dart';
import 'package:tuhfatul_muslim/shared/services/app_globals.dart';

/// The chart's point bubbles are small pills, so a full name (e.g.
/// "Abdullah Al Masud") is shortened to its first two characters ("Ab") —
/// never shown in full.
String _zikrInitials(String name, {required String fallback}) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return fallback;
  return trimmed.substring(0, trimmed.length < 2 ? trimmed.length : 2);
}

/// Zikr stats dashboard (designs `devImg/img_25.png`, `devImg/img_26.png`,
/// and `devImg/img_63.png`),
/// reached from index 2 ("Dashboard") of [ZikrBottomNav].
///
/// UI only — every number and the chart are mock data. Monthly initially shows
/// a rolling 30-day range ending today. Choosing one of the month chips shows
/// that calendar month instead; its graph is horizontally draggable so the
/// first ten days remain readable on a phone-sized viewport.
class ZikrStatsScreen extends StatefulWidget {
  const ZikrStatsScreen({super.key});

  @override
  State<ZikrStatsScreen> createState() => _ZikrStatsScreenState();
}

class _ZikrStatsScreenState extends State<ZikrStatsScreen> {
  int _period = 0; // 0 = Daily, 1 = Weekly, 2 = Monthly
  DateTime? _selectedMonth;
  late final ZikrAnalyticsCubit _cubit = ZikrAnalyticsCubit(zikrRepository);
  late bool _hasAccessToken;

  static const _dailyMock = <double>[0, 900, 0];
  static const _dailyCompetitorMock = <double>[0, 640, 0];

  static const _history = <(String, String)>[
    ('Subhan Allah', '450'),
    ('Alhamdulillah', '312'),
    ('Allahu Akbar', '198'),
  ];

  @override
  void initState() {
    super.initState();
    _hasAccessToken = AuthLocalDataSourceImpl().hasToken;
    if (_hasAccessToken) {
      _cubit.load();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _requestSignIn());
    }
  }

  Future<void> _requestSignIn() async {
    await showZikrLoginRequiredDialog(context);
    if (!mounted) return;
    if (!AuthLocalDataSourceImpl().hasToken) {
      Navigator.of(context).pushReplacementNamed(RouteNames.zikrDashboard);
      return;
    }
    setState(() => _hasAccessToken = true);
    await _cubit.load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Every calendar day the selected monthly window should show — the full
  /// month when a chip is picked, or the rolling last-30-days range by
  /// default — independent of which days the server's `chartData` actually
  /// includes. [_mergedMonthlyPoints] fills in whatever this range has that
  /// the response doesn't, so every date renders (future/no-activity days
  /// included), never skipping one just because nothing happened that day.
  List<DateTime> get _monthlyDayRange {
    final today = _today;
    final selected = _selectedMonth;
    final start = selected == null
        ? today.subtract(const Duration(days: 29))
        : DateTime(selected.year, selected.month);
    final end = selected == null
        ? today
        : DateTime(selected.year, selected.month + 1).subtract(
            const Duration(days: 1),
          );
    final dayCount = end.difference(start).inDays + 1;
    return [for (var i = 0; i < dayCount; i++) start.add(Duration(days: i))];
  }

  /// Indexes `chartData` by every individual calendar date each point
  /// covers (see [TasbihChartPoint.coveredDates]) rather than assuming one
  /// point per day. The server doesn't always return that shape: a custom
  /// weekly/monthly range can come back grouped into multi-day buckets
  /// (`startDate`/`endDate` spanning several days, sharing one aggregate
  /// value) instead — expanding those buckets here means every day they
  /// span still resolves to real data, not a false zero.
  static Map<String, TasbihChartPoint> _chartDataByDate(
    TasbihAnalyticsResponse? analytics,
  ) {
    final byDate = <String, TasbihChartPoint>{};
    for (final point in analytics?.chartData ?? const <TasbihChartPoint>[]) {
      for (final date in point.coveredDates) {
        byDate[date] = point;
      }
    }
    return byDate;
  }

  /// Merges the server's `chartData` (see [_chartDataByDate]) onto every day
  /// in [_monthlyDayRange]. A day the response doesn't cover — no activity
  /// recorded, or a future date — gets zero rather than being dropped or
  /// filled with a placeholder; real API data only, never mock curves.
  List<_ChartDayPoint> _mergedMonthlyPoints(TasbihAnalyticsResponse? analytics) {
    final byDate = _chartDataByDate(analytics);
    return [
      for (final date in _monthlyDayRange)
        _ChartDayPoint(
          date: date,
          value: byDate[_isoDate(date)]?.myPosition ?? 0,
          competitorValue: byDate[_isoDate(date)]?.competitor ?? 0,
        ),
    ];
  }

  static String _isoDate(DateTime date) {
    String pad2(int n) => n.toString().padLeft(2, '0');
    return '${date.year}-${pad2(date.month)}-${pad2(date.day)}';
  }

  /// The 7 calendar days of the selected week, oldest to newest — the same
  /// window [ZikrAnalyticsCubit]'s `offset` resolves to (end = today minus
  /// `offset` weeks; start = 6 days before that).
  List<DateTime> _weeklyDayRange(int offset) {
    final end = _today.subtract(Duration(days: offset * 7));
    final start = end.subtract(const Duration(days: 6));
    return [for (var i = 0; i < 7; i++) start.add(Duration(days: i))];
  }

  /// Merges the server's `chartData` (see [_chartDataByDate]) onto all 7
  /// days of [_weeklyDayRange], the same way [_mergedMonthlyPoints] does
  /// for the month: a day the response doesn't cover gets zero, in
  /// chronological order, so the chart always shows exactly 7 days
  /// regardless of which ones actually had activity.
  List<_ChartDayPoint> _mergedWeeklyPoints(
    TasbihAnalyticsResponse? analytics,
    int offset,
  ) {
    final byDate = _chartDataByDate(analytics);
    return [
      for (final date in _weeklyDayRange(offset))
        _ChartDayPoint(
          date: date,
          value: byDate[_isoDate(date)]?.myPosition ?? 0,
          competitorValue: byDate[_isoDate(date)]?.competitor ?? 0,
        ),
    ];
  }

  void _selectPeriod(int period) {
    setState(() {
      _period = period;
      if (period != 2) _selectedMonth = null;
    });
    if (period == 2) {
      _cubit.loadMonthly();
    } else {
      _cubit.load(period: const ['daily', 'weekly', 'monthly'][period]);
    }
  }

  void _selectMonth(DateTime? month) {
    setState(() {
      _period = 2;
      _selectedMonth = month;
    });
    _cubit.loadMonthly(month: month);
  }

  /// The window's end date (Daily: that day itself; Weekly: the last day of
  /// the 7-day window), used to seed the date picker on the current offset.
  DateTime _windowEnd(int offset) =>
      _today.subtract(Duration(days: _period == 0 ? offset : offset * 7));

  Future<void> _pickDate(BuildContext context, int offset) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _windowEnd(offset),
      firstDate: DateTime(2020),
      lastDate: _today,
    );
    if (picked == null) return;
    await _cubit.jumpToDate(picked);
  }

  /// The day (Daily) or 7-day window (Weekly) the navigator is showing.
  /// Prefers the server's own resolved `startDate`/`endDate` — ground truth
  /// for exactly which days a response covers — and only falls back to a
  /// locally computed window before the first response for this offset
  /// lands.
  String _rangeLabel(
    BuildContext context,
    AppText appText,
    TasbihAnalyticsResponse? analytics,
    int offset,
  ) {
    final serverStart = DateTime.tryParse(analytics?.startDate ?? '');
    final serverEnd = DateTime.tryParse(analytics?.endDate ?? '');
    final isDaily = _period == 0;
    final localEnd = _today.subtract(
      Duration(days: isDaily ? offset : offset * 7),
    );
    final localStart = isDaily
        ? localEnd
        : localEnd.subtract(const Duration(days: 6));
    final start = serverStart ?? localStart;
    final end = serverEnd ?? localEnd;
    final dates = context.localizedDates;
    if (isDaily) return dates.gregorian(end, shortMonth: true);
    return '${dates.gregorian(start, shortMonth: true)} - '
        '${dates.gregorian(end, shortMonth: true)}';
  }

  @override
  Widget build(BuildContext context) {
    // Analytics is a protected dashboard. Do not reveal its placeholder or
    // cached-looking content to guests while the login dialog is displayed.
    if (!_hasAccessToken) {
      return Scaffold(
        backgroundColor: context.pageColor(Colors.white),
        body: const SizedBox.expand(),
      );
    }
    final appText = AppText.of(context);
    final isDaily = _period == 0;
    final isMonthly = _period == 2;

    return BlocProvider.value(
      value: _cubit,
      child: BlocListener<ZikrAnalyticsCubit, ZikrAnalyticsState>(
        listenWhen: (previous, current) =>
            previous.error != current.error &&
            current.error?.contains('AuthenticationRequiredException') == true,
        listener: (context, _) => showZikrLoginRequiredDialog(context),
        child: BlocBuilder<ZikrAnalyticsCubit, ZikrAnalyticsState>(
          builder: (context, analyticsState) {
            final analytics = analyticsState.analytics;
            // Real initials in the chart's point bubbles, never the full
            // name: mine from the signed-in profile, the competitor's from
            // the analytics response.
            final myInitials = _zikrInitials(
              profileNameNotifier.value ?? '',
              fallback: appText.competitorInitials,
            );
            final competitorInitials = _zikrInitials(
              analytics?.competitorName ?? '',
              fallback: appText.competitorInitials,
            );
            // Switching tabs keeps the previous period's `analytics` on
            // screen until the new response lands — only trust it for the
            // monthly chart once it's actually a monthly response, so a
            // stale daily/weekly one isn't briefly drawn as if it were days
            // of a month.
            final monthlyAnalyticsReady =
                isMonthly && analytics?.period == 'monthly';
            // Every day of the selected window, real API values merged in
            // where the response has them, zero elsewhere (future days,
            // days with no recorded activity) — never a dropped date or a
            // mock/placeholder curve.
            final mergedMonthlyPoints = isMonthly
                ? _mergedMonthlyPoints(monthlyAnalyticsReady ? analytics : null)
                : const <_ChartDayPoint>[];
            final isWeekly = !isDaily && !isMonthly;
            final weeklyAnalyticsReady =
                isWeekly && analytics?.period == 'weekly';
            // Same merge as monthly, but for the week's fixed 7 days — the
            // chart always shows Sat..Fri (or whichever 7 the window
            // covers), in order, never fewer just because some had no
            // activity.
            final mergedWeeklyPoints = isWeekly
                ? _mergedWeeklyPoints(
                    weeklyAnalyticsReady ? analytics : null,
                    analyticsState.offset,
                  )
                : const <_ChartDayPoint>[];
            return Scaffold(
              backgroundColor: context.pageColor(Colors.white),
              body: SafeArea(
                child: Stack(
                  children: [
                    ListView(
                      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 96.h),
                      children: [
                        SizedBox(height: 6.h),
                        _Header(title: appText.dashboard),
                        SizedBox(height: 18.h),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _LegendDot(
                                    color: const Color(0xFF3F6B4E),
                                    label: appText.myPosition,
                                  ),
                                  SizedBox(height: 10.h),
                                  _LegendDot(
                                    color: const Color(0xFFA9B96A),
                                    label: appText.myNearestOrCompetitor,
                                  ),
                                ],
                              ),
                            ),
                            _PeriodDropdown(
                              value: isDaily
                                  ? appText.daily
                                  : isMonthly
                                  ? appText.monthly
                                  : appText.weekly,
                              daily: appText.daily,
                              weekly: appText.weekly,
                              monthly: appText.monthly,
                              onSelected: _selectPeriod,
                            ),
                          ],
                        ),
                        if (isMonthly) ...[
                          SizedBox(height: 16.h),
                          _MonthlyFilter(
                            selectedMonth: _selectedMonth,
                            onSelected: _selectMonth,
                          ),
                        ] else ...[
                          SizedBox(height: 14.h),
                          _ZikrDateNavigator(
                            label: _rangeLabel(
                              context,
                              appText,
                              analytics,
                              analyticsState.offset,
                            ),
                            onNewer: analyticsState.offset == 0
                                ? null
                                : () => _cubit.shiftOffset(1),
                            onOlder: () => _cubit.shiftOffset(-1),
                            onTapLabel: () =>
                                _pickDate(context, analyticsState.offset),
                          ),
                        ],
                        SizedBox(height: 18.h),
                        SizedBox(
                          height: 250.h,
                          child: isMonthly
                              ? _ScrollableMonthlyChart(
                                  values: [
                                    for (final point in mergedMonthlyPoints)
                                      point.value,
                                  ],
                                  competitorValues: [
                                    for (final point in mergedMonthlyPoints)
                                      point.competitorValue,
                                  ],
                                  // Every 5th day (plus the final one) gets
                                  // an axis label; the rest stay blank so a
                                  // full month doesn't crowd the axis.
                                  labels: [
                                    for (final (i, point)
                                        in mergedMonthlyPoints.indexed)
                                      i % 5 == 0 ||
                                              i ==
                                                  mergedMonthlyPoints.length -
                                                      1
                                          ? '${point.date.day}'
                                          : '',
                                  ],
                                  // Every day's full date, independent of
                                  // the (sparse) axis labels above — the
                                  // tap/hover tooltip always shows it.
                                  dates: [
                                    for (final point in mergedMonthlyPoints)
                                      context.localizedDates.gregorian(
                                        point.date,
                                        shortMonth: true,
                                      ),
                                  ],
                                  myInitials: myInitials,
                                  competitorInitials: competitorInitials,
                                )
                              : isDaily
                              ? _StatsChart(
                                  values: analytics == null
                                      ? _dailyMock
                                      : [
                                          for (final point
                                              in analytics.chartData)
                                            point.myPosition,
                                        ],
                                  competitorValues: analytics == null
                                      ? _dailyCompetitorMock
                                      : [
                                          for (final point
                                              in analytics.chartData)
                                            point.competitor,
                                        ],
                                  labels: analytics != null
                                      ? [
                                          for (final point
                                              in analytics.chartData)
                                            point.label,
                                        ]
                                      : ['', appText.zikrTodaysValueGraph, ''],
                                  dates: analytics != null
                                      ? [
                                          for (final point
                                              in analytics.chartData)
                                            DateTime.tryParse(
                                                      point.startDate,
                                                    ) ==
                                                    null
                                                ? point.label
                                                : context.localizedDates
                                                      .gregorian(
                                                        DateTime.parse(
                                                          point.startDate,
                                                        ),
                                                        shortMonth: true,
                                                      ),
                                        ]
                                      : const [],
                                  bubbleAll: false,
                                  myInitials: myInitials,
                                  competitorInitials: competitorInitials,
                                  daily: true,
                                )
                              // Weekly: always exactly 7 days, oldest to
                              // newest, real API values merged onto that
                              // fixed range — see [_mergedWeeklyPoints].
                              : _StatsChart(
                                  values: [
                                    for (final point in mergedWeeklyPoints)
                                      point.value,
                                  ],
                                  competitorValues: [
                                    for (final point in mergedWeeklyPoints)
                                      point.competitorValue,
                                  ],
                                  labels: [
                                    for (final point in mergedWeeklyPoints)
                                      context.localizedDates.weekdayShort(
                                        point.date.weekday % 7,
                                      ),
                                  ],
                                  dates: [
                                    for (final point in mergedWeeklyPoints)
                                      context.localizedDates.gregorian(
                                        point.date,
                                        shortMonth: true,
                                      ),
                                  ],
                                  bubbleAll: true,
                                  myInitials: myInitials,
                                  competitorInitials: competitorInitials,
                                  daily: false,
                                ),
                        ),
                        SizedBox(height: 22.h),
                        _TotalPill(
                          label:
                              '${appText.zikrTotalZikr} : ${analytics?.userTotalZikr ?? 780}',
                          trailing: '${analytics?.competitorTotalZikr ?? 854}',
                        ),
                        SizedBox(height: 16.h),
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                label: appText.zikrTotalZikr,
                                value:
                                    '${analytics?.lifetimeTotalCount ?? 132765}',
                              ),
                            ),
                            SizedBox(width: 14.w),
                            Expanded(
                              child: _StatCard(
                                label: appText.zikrMostDoing,
                                value: context.localizedDigits(
                                  '${localizedZikrNameFromKey(appText, zikrKey: analytics?.mostDoingZikrKey ?? '', fallback: analytics?.mostDoingZikrName ?? 'Subhan-Allah')}  ${analytics?.mostDoingZikrCount ?? 34784}',
                                ),
                                italicValue: true,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 24.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              appText.zikrHistory,
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(
                                context,
                              ).pushNamed(RouteNames.zikrHistory),
                              child: Text(appText.seeAll),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        for (final entry
                            in analytics == null
                                ? _history
                                : analytics.recentHistory.map(
                                    (item) => (
                                      localizedZikrNameFromKey(
                                        appText,
                                        zikrKey: item.zikrKey,
                                        fallback: item.zikrName,
                                      ),
                                      '${item.countAdded}',
                                    ),
                                  )) ...[
                          _HistoryRow(
                            name: entry.$1,
                            count: context.localizedDigits(entry.$2),
                          ),
                          Divider(
                            height: 22.h,
                            color: context.lineColor(Color(0xFFEDEFE0)),
                          ),
                        ],
                      ],
                    ),
                    const Align(
                      alignment: Alignment.bottomCenter,
                      child: ZikrBottomNav(selectedIndex: 2),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => Navigator.maybePop(context),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFCBD16B),
                foregroundColor: context.inkColor(Color(0xFF303629)),
                minimumSize: Size(38.r, 38.r),
              ),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 15),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: context.inkColor(AppColor.authLogo),
              fontSize: 19.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12.r,
          height: 12.r,
          decoration: BoxDecoration(
            color: context.surfaceColor(color),
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 8.w),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5.sp,
              color: context.inkColor(Color(0xFF6A7350)),
            ),
          ),
        ),
      ],
    );
  }
}

class _PeriodDropdown extends StatelessWidget {
  const _PeriodDropdown({
    required this.value,
    required this.onSelected,
    required this.daily,
    required this.weekly,
    required this.monthly,
  });

  final String value;
  final ValueChanged<int> onSelected;
  final String daily;
  final String weekly;
  final String monthly;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      onSelected: onSelected,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      itemBuilder: (context) => [
        PopupMenuItem(value: 0, child: Text(daily)),
        PopupMenuItem(value: 1, child: Text(weekly)),
        PopupMenuItem(value: 2, child: Text(monthly)),
      ],
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: context.surfaceColor(Color(0xFFDDE8BA)),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: context.inkColor(Color(0xFF3E4A2A)),
              ),
            ),
            SizedBox(width: 6.w),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18.sp,
              color: context.inkColor(Color(0xFF3E4A2A)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Left/right arrows around the currently shown day or week range, for the
/// Daily and Weekly tabs (Monthly has its own [_MonthlyFilter] instead).
/// Left (chevron_left) steps to the previous day/week — always available,
/// there's no limit how far back it can go. Right (chevron_right) steps
/// forward toward today and is `null` once the current day/week is already
/// showing — there's nowhere forward left to go.
class _ZikrDateNavigator extends StatelessWidget {
  const _ZikrDateNavigator({
    required this.label,
    required this.onOlder,
    required this.onNewer,
    this.onTapLabel,
  });

  final String label;

  /// Left arrow: steps to the previous day/week.
  final VoidCallback onOlder;

  /// Right arrow: steps toward today. Null once the current day/week is
  /// already showing.
  final VoidCallback? onNewer;

  /// Opens a date picker to jump straight to a day/week instead of only
  /// stepping with the arrows. Null leaves the label inert.
  final VoidCallback? onTapLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: context.surfaceColor(Colors.white),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: context.lineColor(Color(0xFFDDE8C1))),
      ),
      child: Row(
        children: [
          _ZikrDateNavArrow(icon: Icons.chevron_left, onTap: onOlder),
          Expanded(
            child: InkWell(
              onTap: onTapLabel,
              borderRadius: BorderRadius.circular(10.r),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 4.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: context.inkColor(Color(0xFF3E4A2A)),
                        ),
                      ),
                    ),
                    if (onTapLabel != null) ...[
                      SizedBox(width: 6.w),
                      Icon(
                        Icons.calendar_month_rounded,
                        size: 15.sp,
                        color: context.inkColor(Color(0xFF6A7350)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          _ZikrDateNavArrow(icon: Icons.chevron_right, onTap: onNewer),
        ],
      ),
    );
  }
}

class _ZikrDateNavArrow extends StatelessWidget {
  const _ZikrDateNavArrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return SizedBox.square(
      dimension: 30.r,
      child: IconButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: context.surfaceColor(
            enabled ? const Color(0xFFDDE8BA) : const Color(0xFFF2F3EA),
          ),
        ),
        icon: Icon(
          icon,
          size: 16.sp,
          color: context.inkColor(
            enabled ? const Color(0xFF3E4A2A) : const Color(0xFFC5CAB8),
          ),
        ),
      ),
    );
  }
}

class _ChartDayPoint {
  const _ChartDayPoint({
    required this.date,
    required this.value,
    required this.competitorValue,
  });

  final DateTime date;
  final double value;
  final double competitorValue;
}

/// The default selection is the most recent 30 days. The remaining chips are
/// all twelve months of the current year, keeping the filter discoverable
/// without taking vertical space from the chart.
class _MonthlyFilter extends StatelessWidget {
  const _MonthlyFilter({required this.selectedMonth, required this.onSelected});

  final DateTime? selectedMonth;
  final ValueChanged<DateTime?> onSelected;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthNames = AppText.of(context).monthNames;
    final currentYearMonths = [
      for (var month = 1; month <= 12; month++) DateTime(now.year, month),
    ];

    return SizedBox(
      height: 38.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: currentYearMonths.length + 1,
        separatorBuilder: (_, _) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          final isRollingRange = index == 0;
          final month = isRollingRange ? null : currentYearMonths[index - 1];
          final selected = isRollingRange
              ? selectedMonth == null
              : selectedMonth?.year == month!.year &&
                    selectedMonth?.month == month.month;
          final label = isRollingRange
              ? 'Last 30 days'
              : monthNames[month!.month - 1];

          return ChoiceChip(
            label: Text(label),
            selected: selected,
            onSelected: (_) => onSelected(month),
            showCheckmark: false,
            labelStyle: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: selected
                  ? const Color(0xFF3E4A2A)
                  : context.inkColor(const Color(0xFF6A7350)),
            ),
            selectedColor: const Color(0xFFDDE8BA),
            backgroundColor: context.surfaceColor(Colors.white),
            side: BorderSide(
              color: selected
                  ? const Color(0xFFDDE8BA)
                  : context.lineColor(const Color(0xFFDDE8C1)),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            padding: EdgeInsets.symmetric(horizontal: 8.w),
          );
        },
      ),
    );
  }
}

/// Scrolls a calendar-month graph horizontally. The child width is calculated
/// so ten days fill the initial viewport; the remaining days are revealed by
/// dragging right, matching the monthly design's progress rail.
class _ScrollableMonthlyChart extends StatefulWidget {
  const _ScrollableMonthlyChart({
    required this.values,
    required this.competitorValues,
    required this.labels,
    required this.dates,
    required this.myInitials,
    required this.competitorInitials,
  });

  final List<double> values;
  final List<double> competitorValues;
  final List<String> labels;

  /// Every point's full display date, for the tap/hover tooltip — parallel
  /// to [values], independent of [labels]' sparser 5-day gridline text.
  final List<String> dates;
  final String myInitials;
  final String competitorInitials;

  @override
  State<_ScrollableMonthlyChart> createState() =>
      _ScrollableMonthlyChartState();
}

class _ScrollableMonthlyChartState extends State<_ScrollableMonthlyChart> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const horizontalChartPadding = 40.0;
        final pointGap = (constraints.maxWidth - horizontalChartPadding) / 9;
        final contentWidth =
            horizontalChartPadding + pointGap * (widget.values.length - 1);

        return ScrollbarTheme(
          data: ScrollbarThemeData(
            thumbColor: const WidgetStatePropertyAll(Color(0xFFC8D792)),
            trackColor: const WidgetStatePropertyAll(Color(0xFFE8EFD5)),
            trackBorderColor: const WidgetStatePropertyAll(Color(0xFFE8EFD5)),
            thickness: const WidgetStatePropertyAll(10),
            radius: const Radius.circular(8),
          ),
          child: Scrollbar(
            controller: _controller,
            thumbVisibility: true,
            trackVisibility: true,
            child: SingleChildScrollView(
              controller: _controller,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: contentWidth,
                height: constraints.maxHeight,
                child: _StatsChart(
                  values: widget.values,
                  competitorValues: widget.competitorValues,
                  labels: widget.labels,
                  dates: widget.dates,
                  bubbleAll: true,
                  myInitials: widget.myInitials,
                  competitorInitials: widget.competitorInitials,
                  daily: false,
                  // Keep day labels above the horizontal scrollbar. Without
                  // this reserve, labels such as 10/11 sit under its thumb.
                  bottomPadding: 42,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TotalPill extends StatelessWidget {
  const _TotalPill({required this.label, required this.trailing});

  final String label;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: context.lineColor(Color(0xFFDDE8C1))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 14.h),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.surfaceColor(Color(0xFFDDE8BA)),
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: context.inkColor(Color(0xFF3E4A2A)),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 18.w),
            child: Row(
              children: [
                Container(
                  width: 8.r,
                  height: 8.r,
                  decoration: const BoxDecoration(
                    color: Color(0xFFA9B96A),
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  trailing,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: context.inkColor(Color(0xFF6A7350)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    this.italicValue = false,
  });

  final String label;
  final String value;
  final bool italicValue;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: Padding(
        padding: EdgeInsets.fromLTRB(14.w, 18.h, 14.w, 18.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                color: context.inkColor(Color(0xFF3B4430)),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                fontStyle: italicValue ? FontStyle.italic : FontStyle.normal,
                color: context.inkColor(Color(0xFF2C3320)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC7D2A0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(16)),
      );
    const dash = 5.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.name, required this.count});

  final String name;
  final String count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32.r,
          height: 32.r,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: context.lineColor(Color(0xFFE3E7D3))),
          ),
          child: Icon(
            Icons.menu_book_rounded,
            size: 16.sp,
            color: context.inkColor(Color(0xFF8B9865)),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14.sp,
              color: context.inkColor(Color(0xFF2C3320)),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          context.localizedDigits(count),
          style: TextStyle(fontSize: 12.sp, color: const Color(0xFFA1AD59)),
        ),
      ],
    );
  }
}

/// Area-line chart: draws my position as a solid line and the competitor's
/// as a second line in the legend's olive color, each with its own dots.
/// "Weekly" shows an "Ab" bubble with the competitor's initials over every
/// one of their points; "Daily" shows it only where they have activity.
///
/// Tapping (any platform) or hovering (desktop/web) the nearest point to
/// the pointer shows a tooltip with that point's date and my/competitor
/// values — tapping the same point again, or moving the pointer off the
/// chart, dismisses it.
class _StatsChart extends StatefulWidget {
  const _StatsChart({
    required this.values,
    required this.competitorValues,
    required this.labels,
    required this.dates,
    required this.bubbleAll,
    required this.myInitials,
    required this.competitorInitials,
    required this.daily,
    this.bottomPadding = 22,
  });

  final List<double> values;
  final List<double> competitorValues;
  final List<String> labels;

  /// Every point's full display date, for the tooltip — parallel to
  /// [values], independent of [labels] (which may be blank for a point
  /// that isn't on an axis gridline, e.g. monthly's 5-day spacing).
  final List<String> dates;
  final bool bubbleAll;
  final String myInitials;
  final String competitorInitials;
  final bool daily;
  final double bottomPadding;

  @override
  State<_StatsChart> createState() => _StatsChartState();
}

class _StatsChartState extends State<_StatsChart> {
  int? _selectedIndex;

  void _setSelected(int? index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  @override
  void didUpdateWidget(covariant _StatsChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // New data (a different day/week/month navigated to) always means a
    // freshly-built `values` list — dismiss a tooltip left open from
    // whatever was shown before, rather than pointing it at the wrong day.
    if (oldWidget.values != widget.values && _selectedIndex != null) {
      _selectedIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final geometry = _ChartGeometry(size, widget.bottomPadding);
        final count = widget.values.length;
        final selected = _selectedIndex;

        return MouseRegion(
          onHover: (event) =>
              _setSelected(geometry.nearestIndex(event.localPosition.dx, count)),
          onExit: (_) => _setSelected(null),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              final index = geometry.nearestIndex(
                details.localPosition.dx,
                count,
              );
              _setSelected(_selectedIndex == index ? null : index);
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CustomPaint(
                  size: size,
                  painter: _StatsChartPainter(
                    values: widget.values,
                    competitorValues: widget.competitorValues,
                    labels: widget.labels,
                    bubbleAll: widget.bubbleAll,
                    myInitials: widget.myInitials,
                    competitorInitials: widget.competitorInitials,
                    daily: widget.daily,
                    bottomPadding: widget.bottomPadding,
                  ),
                ),
                if (selected != null && selected < count)
                  _buildTooltip(geometry, size, selected),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTooltip(_ChartGeometry geometry, Size size, int index) {
    final maxY = _niceMaxY(widget.values, widget.competitorValues);
    final count = widget.values.length;
    final hasCompetitor = index < widget.competitorValues.length;
    final myY = geometry.yAt(widget.values[index], maxY);
    final competitorY = hasCompetitor
        ? geometry.yAt(widget.competitorValues[index], maxY)
        : myY;
    final topY = myY < competitorY ? myY : competitorY;
    final x = geometry
        .xAt(index, count)
        .clamp(50.w, (size.width - 50.w).clamp(50.w, double.infinity));
    final top = (topY - 78.h).clamp(0.0, size.height);
    final date = index < widget.dates.length ? widget.dates[index] : '';

    return Positioned(
      left: x,
      top: top,
      child: FractionalTranslation(
        translation: const Offset(-0.5, 0),
        child: _ChartTooltip(
          date: date,
          myLabel: widget.myInitials,
          myValue: widget.values[index],
          competitorLabel: widget.competitorInitials,
          competitorValue: hasCompetitor
              ? widget.competitorValues[index]
              : null,
        ),
      ),
    );
  }
}

/// The date + my/competitor values shown when [_StatsChart] is tapped or
/// hovered at a point.
class _ChartTooltip extends StatelessWidget {
  const _ChartTooltip({
    required this.date,
    required this.myLabel,
    required this.myValue,
    required this.competitorLabel,
    required this.competitorValue,
  });

  final String date;
  final String myLabel;
  final double myValue;
  final String competitorLabel;
  final double? competitorValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFDDE8C1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .12),
            blurRadius: 10,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (date.isNotEmpty) ...[
            Text(
              date,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3E4A2A),
              ),
            ),
            SizedBox(height: 6.h),
          ],
          _row(context, myLabel, myValue, const Color(0xFF3F6B4E)),
          if (competitorValue != null) ...[
            SizedBox(height: 4.h),
            _row(
              context,
              competitorLabel,
              competitorValue!,
              const Color(0xFF6C7A3C),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, double value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8.r,
          height: 8.r,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 6.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        SizedBox(width: 6.w),
        Text(
          context.localizedDigits('${value.round()}'),
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2C3320),
          ),
        ),
      ],
    );
  }
}

/// Pixel geometry of [_StatsChartPainter]'s plot area — mirrors its local
/// `xAt`/`yAt` exactly, so [_StatsChart]'s tap/hover hit-testing and tooltip
/// placement land on precisely the point the painter actually drew, not a
/// second copy of the same formula that could drift out of sync with it.
class _ChartGeometry {
  _ChartGeometry(Size size, double bottomPadding)
    : chartLeft = _leftPad,
      chartRight = size.width - _rightPad,
      chartTop = _topPad,
      chartBottom = size.height - bottomPadding;

  static const _leftPad = 34.0;
  static const _topPad = 44.0;
  static const _rightPad = 6.0;

  final double chartLeft;
  final double chartRight;
  final double chartTop;
  final double chartBottom;

  double get _width => chartRight - chartLeft;
  double get _height => chartBottom - chartTop;

  double xAt(int i, int count) =>
      count < 2 ? chartLeft + _width / 2 : chartLeft + _width * (i / (count - 1));

  double yAt(double v, double maxY) => chartBottom - _height * (v / maxY);

  /// The closest point index to a tapped/hovered x position.
  int nearestIndex(double dx, int count) {
    if (count <= 1) return 0;
    final stepX = _width / (count - 1);
    return ((dx - chartLeft) / stepX).round().clamp(0, count - 1);
  }
}

/// Candidate top-of-chart values, each a multiple of 4 so the four gridlines
/// below land on clean numbers. Real zikr counts (tens to a few hundred) are
/// tiny next to a fixed 0–1000 scale — every day's line hugs the bottom and
/// looks the same no matter how the count changes. Scaling to the data's
/// own range makes day-to-day/week-to-week changes actually visible. Shared
/// by [_StatsChartPainter] (drawing the gridlines) and [_StatsChartState]
/// (positioning the tooltip), so both agree on the same scale.
double _niceMaxY(List<double> values, List<double> competitorValues) {
  const niceMaxCandidates = [
    20,
    40,
    100,
    200,
    400,
    1000,
    2000,
    4000,
    10000,
    20000,
    40000,
    100000,
  ];
  final rawMax = [
    ...values,
    ...competitorValues,
  ].fold<double>(0, (max, v) => v > max ? v : max);
  for (final step in niceMaxCandidates) {
    if (rawMax <= step) return step.toDouble();
  }
  return ((rawMax / 20000).ceil() * 20000).toDouble();
}

class _StatsChartPainter extends CustomPainter {
  _StatsChartPainter({
    required this.values,
    required this.competitorValues,
    required this.labels,
    required this.bubbleAll,
    required this.myInitials,
    required this.competitorInitials,
    required this.daily,
    required this.bottomPadding,
  });

  final List<double> values;
  final List<double> competitorValues;
  final List<String> labels;
  final bool bubbleAll;
  final String myInitials;
  final String competitorInitials;
  final bool daily;
  final double bottomPadding;

  double get _maxY => _niceMaxY(values, competitorValues);

  List<int> get _steps {
    final max = _maxY;
    return [for (var i = 0; i <= 4; i++) (max * i / 4).round()];
  }

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 34.0;
    const topPad = 44.0;
    final bottomPad = bottomPadding;
    final chartLeft = leftPad;
    final chartRight = size.width - 6;
    final chartTop = topPad;
    final chartBottom = size.height - bottomPad;
    final chartWidth = chartRight - chartLeft;
    final chartHeight = chartBottom - chartTop;
    final maxY = _maxY;

    // A single point (e.g. a one-day custom range) has no span to divide
    // by — center it instead of dividing by zero.
    double xAt(int i) => values.length < 2
        ? chartLeft + chartWidth / 2
        : chartLeft + chartWidth * (i / (values.length - 1));
    double yAt(double v) => chartBottom - chartHeight * (v / maxY);

    final gridPaint = Paint()
      ..color = const Color(0xFFECEFE1)
      ..strokeWidth = 1;
    for (final step in _steps) {
      final y = yAt(step.toDouble());
      canvas.drawLine(Offset(chartLeft, y), Offset(chartRight, y), gridPaint);
      _text(
        canvas,
        '$step',
        Offset(chartLeft - 8, y),
        color: const Color(0xFF9AA279),
        fontSize: 9,
        anchorRight: true,
        anchorMiddleY: true,
      );
    }

    for (var i = 0; i < labels.length; i++) {
      if (labels[i].isEmpty) continue;
      _text(
        canvas,
        labels[i],
        Offset(xAt(i), chartBottom + 6),
        color: const Color(0xFF6A7350),
        fontSize: 10,
        anchorCenterX: true,
      );
    }

    final points = [
      for (var i = 0; i < values.length; i++) Offset(xAt(i), yAt(values[i])),
    ];

    final areaPath = Path()..moveTo(points.first.dx, chartBottom);
    for (final p in points) {
      areaPath.lineTo(p.dx, p.dy);
    }
    areaPath
      ..lineTo(points.last.dx, chartBottom)
      ..close();
    final fill = daily
        ? const [Color(0x66A6C97E), Color(0x11A6C97E)]
        : const [Color(0x559BA7D8), Color(0x0F9BA7D8)];
    canvas.drawPath(
      areaPath,
      Paint()
        ..shader =
            LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: fill,
            ).createShader(
              Rect.fromLTRB(chartLeft, chartTop, chartRight, chartBottom),
            ),
    );

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      linePath.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = const Color(0xFF3A4A2E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      if (daily && values[i] == 0) continue;
      canvas.drawCircle(p, 5, Paint()..color = Colors.white);
      canvas.drawCircle(
        p,
        5,
        Paint()
          ..color = const Color(0xFF8FA08A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
      if (bubbleAll || (daily && values[i] > 0)) {
        _bubble(
          canvas,
          size,
          Offset(p.dx, p.dy - 16),
          label: myInitials,
          pillColor: const Color(0xFFBFD19B),
          dotColor: const Color(0xFF3F6B4E),
        );
      }
    }

    // Competitor's own line, in the legend's olive — same x positions, their
    // own values. Skipped once there's nothing to compare (fewer values than
    // mine, e.g. the loading placeholder).
    if (competitorValues.length == values.length) {
      final competitorPoints = [
        for (var i = 0; i < competitorValues.length; i++)
          Offset(xAt(i), yAt(competitorValues[i])),
      ];
      final competitorLinePath = Path()
        ..moveTo(competitorPoints.first.dx, competitorPoints.first.dy);
      for (final p in competitorPoints.skip(1)) {
        competitorLinePath.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
        competitorLinePath,
        Paint()
          ..color = const Color(0xFFA9B96A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
      for (var i = 0; i < competitorPoints.length; i++) {
        final p = competitorPoints[i];
        if (daily && competitorValues[i] == 0) continue;
        canvas.drawCircle(p, 5, Paint()..color = Colors.white);
        canvas.drawCircle(
          p,
          5,
          Paint()
            ..color = const Color(0xFFA9B96A)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6,
        );
        if (bubbleAll || (daily && competitorValues[i] > 0)) {
          _bubble(
            canvas,
            size,
            Offset(p.dx, p.dy - 16),
            label: competitorInitials,
            pillColor: const Color(0xFFCDD891),
            dotColor: const Color(0xFF6C7A3C),
          );
        }
      }
    }
  }

  void _bubble(
    Canvas canvas,
    Size size,
    Offset anchor, {
    required String label,
    required Color pillColor,
    required Color dotColor,
  }) {
    const w = 42.0;
    const h = 22.0;
    var left = anchor.dx - w / 2;
    left = left.clamp(0.0, size.width - w);
    final rect = Rect.fromLTWH(left, anchor.dy - h, w, h);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(11)),
      Paint()..color = pillColor,
    );
    canvas.drawCircle(
      Offset(rect.left + 12, rect.center.dy),
      3,
      Paint()..color = dotColor,
    );
    _text(
      canvas,
      label,
      Offset(rect.left + 19, rect.center.dy),
      color: const Color(0xFF3E4A2A),
      fontSize: 10,
      anchorMiddleY: true,
    );
  }

  void _text(
    Canvas canvas,
    String text,
    Offset offset, {
    required Color color,
    required double fontSize,
    bool anchorRight = false,
    bool anchorCenterX = false,
    bool anchorMiddleY = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    var dx = offset.dx;
    if (anchorRight) dx -= tp.width;
    if (anchorCenterX) dx -= tp.width / 2;
    var dy = offset.dy;
    if (anchorMiddleY) dy -= tp.height / 2;
    tp.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(covariant _StatsChartPainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.competitorValues != competitorValues ||
      oldDelegate.labels != labels ||
      oldDelegate.myInitials != myInitials ||
      oldDelegate.competitorInitials != competitorInitials ||
      oldDelegate.daily != daily ||
      oldDelegate.bottomPadding != bottomPadding;
}
