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
import 'package:tuhfatul_muslim/features/zikr/presentation/bloc/zikr_analytics_cubit.dart';
import 'package:tuhfatul_muslim/features/zikr/presentation/zikr_login_dialog.dart';
import 'package:tuhfatul_muslim/features/zikr/zikr_dependencies.dart';

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

  static const _weekly = <double>[490, 690, 880, 240, 250, 760, 180];
  // Saturday first, as an index counted from Sunday.
  static const _weekDayIndexes = [6, 0, 1, 2, 3, 4, 5];

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

  List<_MonthlyPoint> get _monthlyPoints {
    final today = _today;
    final selected = _selectedMonth;
    final start = selected == null
        ? today.subtract(const Duration(days: 29))
        : DateTime(selected.year, selected.month);
    final end = selected == null
        ? today
        : DateTime(selected.year, selected.month + 1);
    final dayCount = end.difference(start).inDays + (selected == null ? 1 : 0);

    return List.generate(dayCount, (index) {
      final date = start.add(Duration(days: index));
      // Deterministic placeholder values until analytics is wired to the API.
      const samples = [500.0, 960.0, 190.0, 220.0, 840.0, 420.0, 180.0];
      return _MonthlyPoint(
        date: date,
        value: samples[(date.day + date.month * 2) % samples.length],
      );
    });
  }

  void _selectPeriod(int period) {
    setState(() {
      _period = period;
      if (period != 2) _selectedMonth = null;
    });
    _cubit.load(period: const ['daily', 'weekly', 'monthly'][period]);
  }

  void _selectMonth(DateTime? month) {
    setState(() {
      _period = 2;
      _selectedMonth = month;
    });
    _cubit.load(period: 'monthly');
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
    final monthlyPoints = _monthlyPoints;

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
                        ],
                        SizedBox(height: 18.h),
                        SizedBox(
                          height: 250.h,
                          child: isMonthly
                              ? _ScrollableMonthlyChart(
                                  points: monthlyPoints,
                                  competitorInitials:
                                      appText.competitorInitials,
                                )
                              : _StatsChart(
                                  values: analytics == null
                                      ? (isDaily ? const [0, 900, 0] : _weekly)
                                      : [
                                          for (final point
                                              in analytics.chartData)
                                            point.myPosition,
                                        ],
                                  labels: isDaily
                                      ? ['', appText.zikrTodaysValueGraph, '']
                                      : analytics == null
                                      ? [
                                          for (final i in _weekDayIndexes)
                                            context.localizedDates.weekdayShort(
                                              i,
                                            ),
                                        ]
                                      : [
                                          for (final point
                                              in analytics.chartData)
                                            point.label,
                                        ],
                                  bubbleAll: !isDaily,
                                  competitorInitials:
                                      appText.competitorInitials,
                                  daily: isDaily,
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
                                  '${analytics?.mostDoingZikrName ?? 'Subhan-Allah'}  ${analytics?.mostDoingZikrCount ?? 34784}',
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
                                    (item) =>
                                        (item.zikrName, '${item.countAdded}'),
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

class _MonthlyPoint {
  const _MonthlyPoint({required this.date, required this.value});

  final DateTime date;
  final double value;
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
    required this.points,
    required this.competitorInitials,
  });

  final List<_MonthlyPoint> points;
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
            horizontalChartPadding + pointGap * (widget.points.length - 1);

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
                  values: [for (final point in widget.points) point.value],
                  labels: [
                    for (final point in widget.points)
                      point.date.day.toString(),
                  ],
                  bubbleAll: true,
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
        Text(
          name,
          style: TextStyle(
            fontSize: 14.sp,
            color: context.inkColor(Color(0xFF2C3320)),
          ),
        ),
        const Spacer(),
        Text(
          context.localizedDigits(count),
          style: TextStyle(fontSize: 12.sp, color: const Color(0xFFA1AD59)),
        ),
      ],
    );
  }
}

/// Area-line chart: "Weekly" draws a 7-point line with an "Ab" bubble over every
/// node; "Daily" draws a single peak with one bubble.
class _StatsChart extends StatelessWidget {
  const _StatsChart({
    required this.values,
    required this.labels,
    required this.bubbleAll,
    required this.competitorInitials,
    required this.daily,
    this.bottomPadding = 22,
  });

  final List<double> values;
  final List<String> labels;
  final bool bubbleAll;
  final String competitorInitials;
  final bool daily;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _StatsChartPainter(
        values: values,
        labels: labels,
        bubbleAll: bubbleAll,
        competitorInitials: competitorInitials,
        daily: daily,
        bottomPadding: bottomPadding,
      ),
    );
  }
}

class _StatsChartPainter extends CustomPainter {
  _StatsChartPainter({
    required this.values,
    required this.labels,
    required this.bubbleAll,
    required this.competitorInitials,
    required this.daily,
    required this.bottomPadding,
  });

  final List<double> values;
  final List<String> labels;
  final bool bubbleAll;
  final String competitorInitials;
  final bool daily;
  final double bottomPadding;

  static const _maxY = 1000.0;
  static const _steps = [0, 250, 500, 750, 1000];

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

    double xAt(int i) => chartLeft + chartWidth * (i / (values.length - 1));
    double yAt(double v) => chartBottom - chartHeight * (v / _maxY);

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
        _bubble(canvas, size, Offset(p.dx, p.dy - 16));
      }
    }
  }

  void _bubble(Canvas canvas, Size size, Offset anchor) {
    const w = 42.0;
    const h = 22.0;
    var left = anchor.dx - w / 2;
    left = left.clamp(0.0, size.width - w);
    final rect = Rect.fromLTWH(left, anchor.dy - h, w, h);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(11)),
      Paint()..color = const Color(0xFFCDD891),
    );
    canvas.drawCircle(
      Offset(rect.left + 12, rect.center.dy),
      3,
      Paint()..color = const Color(0xFF6C7A3C),
    );
    _text(
      canvas,
      competitorInitials,
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
      oldDelegate.labels != labels ||
      oldDelegate.daily != daily ||
      oldDelegate.bottomPadding != bottomPadding;
}
