import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';

/// Full recitation-history flow opened from the Dua dashboard's "See All"
/// action. Its Daily, Weekly, and Monthly views follow `devImg/img_30.png`
/// through `img_34.png` while the history endpoint is still pending.
class DuaRecitationHistoryScreen extends StatefulWidget {
  const DuaRecitationHistoryScreen({super.key});

  @override
  State<DuaRecitationHistoryScreen> createState() =>
      _DuaRecitationHistoryScreenState();
}

class _DuaRecitationHistoryScreenState
    extends State<DuaRecitationHistoryScreen> {
  _RecitationPeriod _period = _RecitationPeriod.daily;
  final _expandedDates = <String>{};
  bool _monthPickerOpen = false;
  int _selectedDay = 9;

  void _toggleDate(String date) => setState(() {
    if (!_expandedDates.add(date)) _expandedDates.remove(date);
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.pageColor(Colors.white),
    body: SafeArea(
      child: Column(
        children: [
          _HistoryTopBar(
            period: _period,
            onPeriodChanged: (period) => setState(() => _period = period),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: switch (_period) {
                _RecitationPeriod.daily => _DailyHistory(
                  key: const ValueKey('daily-history'),
                  selectedDay: _selectedDay,
                  onDayChanged: (day) => setState(() => _selectedDay = day),
                ),
                _RecitationPeriod.weekly => _WeeklyHistory(
                  key: const ValueKey('weekly-history'),
                  selectedDay: _selectedDay,
                  expandedDates: _expandedDates,
                  onDayChanged: (day) => setState(() => _selectedDay = day),
                  onToggle: _toggleDate,
                ),
                _RecitationPeriod.monthly => _MonthlyHistory(
                  key: const ValueKey('monthly-history'),
                  selectedDay: _selectedDay,
                  monthPickerOpen: _monthPickerOpen,
                  expandedDates: _expandedDates,
                  onDayChanged: (day) => setState(() => _selectedDay = day),
                  onMonthPickerToggle: () =>
                      setState(() => _monthPickerOpen = !_monthPickerOpen),
                  onToggle: _toggleDate,
                ),
              },
            ),
          ),
        ],
      ),
    ),
  );
}

enum _RecitationPeriod { daily, weekly, monthly }

extension on _RecitationPeriod {
  String get label => switch (this) {
    _RecitationPeriod.daily => 'Daily',
    _RecitationPeriod.weekly => 'Weekly',
    _RecitationPeriod.monthly => 'Monthly',
  };
}

class _HistoryTopBar extends StatelessWidget {
  const _HistoryTopBar({required this.period, required this.onPeriodChanged});

  final _RecitationPeriod period;
  final ValueChanged<_RecitationPeriod> onPeriodChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 6.h),
    child: Row(
      children: [
        _RoundAction(
          icon: Icons.close_rounded,
          onTap: () => Navigator.of(context).maybePop(),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Container(
            height: 46.h,
            padding: EdgeInsets.all(4.r),
            decoration: BoxDecoration(
              color: context.surfaceColor(Colors.white),
              borderRadius: BorderRadius.circular(25.r),
              border: Border.all(
                color: context.lineColor(const Color(0xFFF0F0EB)),
              ),
            ),
            child: Row(
              children: [
                for (final item in _RecitationPeriod.values)
                  Expanded(
                    child: InkWell(
                      onTap: () => onPeriodChanged(item),
                      borderRadius: BorderRadius.circular(21.r),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: item == period
                              ? context.surfaceColor(const Color(0xFFDDE9B4))
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(21.r),
                        ),
                        child: Text(
                          item.label,
                          style: TextStyle(
                            color: context.textInkColor(
                              const Color(0xFF2E3227),
                            ),
                            fontSize: 11.sp,
                            fontWeight: item == period
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SizedBox(width: 8.w),
        const _RoundAction(icon: Icons.ios_share_outlined),
      ],
    ),
  );
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: context.surfaceColor(Colors.white),
    shape: const CircleBorder(),
    child: InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: SizedBox.square(
        dimension: 44.r,
        child: Icon(
          icon,
          size: 20.sp,
          color: context.textInkColor(const Color(0xFF30312D)),
        ),
      ),
    ),
  );
}

class _DailyHistory extends StatelessWidget {
  const _DailyHistory({
    super.key,
    required this.selectedDay,
    required this.onDayChanged,
  });

  final int selectedDay;
  final ValueChanged<int> onDayChanged;

  @override
  Widget build(BuildContext context) => ListView(
    padding: EdgeInsets.fromLTRB(16.w, 10.h, 10.w, 24.h),
    children: [
      const _HistoryTitle(),
      SizedBox(height: 22.h),
      _WeekStrip(selectedDay: selectedDay, onDayChanged: onDayChanged),
      SizedBox(height: 22.h),
      const _TimelineGroup(
        time: '8:00 AM',
        children: [
          _RecitationCardData(
            title: 'Added DUA names here..',
            category: 'Category name here',
            arabic: 'Arabic dua here . . . .',
            surface: Color(0xFFFFE9E2),
            accent: Color(0xFFFF604D),
          ),
        ],
      ),
      const _TimelineGroup(
        time: '9:30 AM',
        children: [
          _RecitationCardData(
            title: 'Added DUA names here..',
            category: 'Category name here',
            arabic: 'Arabic dua here . . . .',
            surface: Color(0xFFE9E7FF),
            accent: Color(0xFF5B54E8),
          ),
        ],
      ),
      const _TimelineGroup(
        time: '10:00 AM',
        children: [
          _RecitationCardData(
            title: 'Added DUA names here..',
            category: 'Category name here',
            arabic: 'Arabic dua here . . . .',
            surface: Color(0xFFFFF3D4),
            accent: Color(0xFFE9A51C),
          ),
        ],
      ),
      const _TimelineGroup(
        time: '12:30 PM',
        children: [
          _RecitationCardData(
            title: 'Added DUA names here..',
            category: 'Category name here',
            arabic: 'Arabic dua here . . . .',
            surface: Color(0xFFE6F4EC),
            accent: Color(0xFF4BA779),
          ),
        ],
      ),
    ],
  );
}

class _HistoryTitle extends StatelessWidget {
  const _HistoryTitle();

  @override
  Widget build(BuildContext context) => Text(
    'Recitation history',
    style: TextStyle(
      color: context.textInkColor(const Color(0xFFA3B35E)),
      fontFamily: 'serif',
      fontSize: 24.sp,
      fontWeight: FontWeight.w700,
      fontStyle: FontStyle.italic,
    ),
  );
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.selectedDay, required this.onDayChanged});

  final int selectedDay;
  final ValueChanged<int> onDayChanged;

  static const _days = [
    ('Sun', 6),
    ('Mon', 7),
    ('Tue', 8),
    ('Wed', 9),
    ('Thu', 10),
    ('Fri', 11),
    ('Sat', 12),
  ];

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final day in _days)
        Expanded(
          child: InkWell(
            onTap: () => onDayChanged(day.$2),
            borderRadius: BorderRadius.circular(24.r),
            child: Column(
              children: [
                Text(
                  day.$1,
                  style: TextStyle(
                    fontSize: 9.sp,
                    color: day.$2 == selectedDay
                        ? context.textInkColor(const Color(0xFF2A2E27))
                        : context.textInkColor(const Color(0xFF8A8D85)),
                    fontWeight: day.$2 == selectedDay
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                ),
                SizedBox(height: 8.h),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 36.r,
                  height: 36.r,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.surfaceColor(
                      day.$2 == selectedDay
                          ? const Color(0xFFA9B75A)
                          : const Color(0xFFE2ECB8),
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${day.$2}',
                    style: TextStyle(
                      color: day.$2 == selectedDay
                          ? Colors.white
                          : context.textInkColor(const Color(0xFF747866)),
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: 5.h),
                Container(
                  width: 5.r,
                  height: 5.r,
                  decoration: BoxDecoration(
                    color: day.$2 == selectedDay || day.$2 == 7 || day.$2 == 10
                        ? context.surfaceColor(const Color(0xFFA9B75A))
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}

class _TimelineGroup extends StatelessWidget {
  const _TimelineGroup({required this.time, required this.children});

  final String time;
  final List<_RecitationCardData> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: 10.h),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 62.w,
          child: Padding(
            padding: EdgeInsets.only(top: 13.h),
            child: Text(
              time,
              style: TextStyle(
                color: context.textInkColor(const Color(0xFF99978F)),
                fontSize: 10.sp,
              ),
            ),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              for (final child in children) _RecitationCard(data: child),
            ],
          ),
        ),
      ],
    ),
  );
}

class _RecitationCardData {
  const _RecitationCardData({
    required this.title,
    required this.category,
    required this.arabic,
    required this.surface,
    required this.accent,
  });

  final String title;
  final String category;
  final String arabic;
  final Color surface;
  final Color accent;
}

class _RecitationCard extends StatelessWidget {
  const _RecitationCard({required this.data});

  final _RecitationCardData data;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(14.r),
    decoration: BoxDecoration(
      color: context.surfaceColor(data.surface),
      borderRadius: BorderRadius.circular(23.r),
      border: Border.all(color: context.lineColor(data.surface)),
    ),
    child: Row(
      children: [
        Container(
          width: 40.r,
          height: 40.r,
          decoration: BoxDecoration(
            color: context.surfaceColor(data.accent),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.menu_book_rounded, color: Colors.white),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.textInkColor(const Color(0xFF292A28)),
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 3.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: context.surfaceColor(Colors.white),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  data.category,
                  style: TextStyle(
                    color: context.textInkColor(const Color(0xFF4E4E4B)),
                    fontSize: 8.sp,
                  ),
                ),
              ),
              SizedBox(height: 5.h),
              Text(
                data.arabic,
                style: TextStyle(
                  color: context.textInkColor(const Color(0xFF53534D)),
                  fontSize: 10.sp,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 8.w),
        Container(
          width: 28.r,
          height: 28.r,
          decoration: BoxDecoration(
            color: context.surfaceColor(Colors.white),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.play_arrow_rounded,
            size: 17.sp,
            color: context.inkColor(data.accent),
          ),
        ),
      ],
    ),
  );
}

class _WeeklyHistory extends StatelessWidget {
  const _WeeklyHistory({
    super.key,
    required this.selectedDay,
    required this.expandedDates,
    required this.onDayChanged,
    required this.onToggle,
  });

  final int selectedDay;
  final Set<String> expandedDates;
  final ValueChanged<int> onDayChanged;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) => ListView(
    padding: EdgeInsets.fromLTRB(16.w, 10.h, 10.w, 24.h),
    children: [
      const _HistoryTitle(),
      SizedBox(height: 22.h),
      _WeekStrip(selectedDay: selectedDay, onDayChanged: onDayChanged),
      SizedBox(height: 16.h),
      for (final summary in _weeklySummaries) ...[
        _HistorySummary(
          summary: summary,
          expanded: expandedDates.contains(summary.date),
          onTap: () => onToggle(summary.date),
        ),
        SizedBox(height: 11.h),
      ],
    ],
  );
}

class _MonthlyHistory extends StatelessWidget {
  const _MonthlyHistory({
    super.key,
    required this.selectedDay,
    required this.monthPickerOpen,
    required this.expandedDates,
    required this.onDayChanged,
    required this.onMonthPickerToggle,
    required this.onToggle,
  });

  final int selectedDay;
  final bool monthPickerOpen;
  final Set<String> expandedDates;
  final ValueChanged<int> onDayChanged;
  final VoidCallback onMonthPickerToggle;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) => ListView(
    padding: EdgeInsets.fromLTRB(16.w, 10.h, 10.w, 24.h),
    children: [
      _MonthSelector(expanded: monthPickerOpen, onTap: onMonthPickerToggle),
      SizedBox(height: 10.h),
      _MonthCalendar(selectedDay: selectedDay, onDayChanged: onDayChanged),
      SizedBox(height: 16.h),
      _HistorySummary(
        summary: _weeklySummaries[3],
        expanded: expandedDates.contains(_weeklySummaries[3].date),
        onTap: () => onToggle(_weeklySummaries[3].date),
      ),
      SizedBox(height: 11.h),
      _HistorySummary(
        summary: _weeklySummaries[4],
        expanded: expandedDates.contains(_weeklySummaries[4].date),
        muted: true,
        onTap: () => onToggle(_weeklySummaries[4].date),
      ),
      SizedBox(height: 11.h),
      _HistorySummary(
        summary: _weeklySummaries[5],
        expanded: expandedDates.contains(_weeklySummaries[5].date),
        muted: true,
        onTap: () => onToggle(_weeklySummaries[5].date),
      ),
    ],
  );
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({required this.expanded, required this.onTap});

  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
          decoration: BoxDecoration(
            color: context.surfaceColor(const Color(0xFFFAFCF3)),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: context.lineColor(const Color(0xFFE3EBCE)),
            ),
          ),
          child: Row(
            children: [
              Text(
                'August',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                  color: context.textInkColor(const Color(0xFF596439)),
                ),
              ),
              SizedBox(width: 7.w),
              Text(
                '2026',
                style: TextStyle(
                  color: context.textInkColor(const Color(0xFF596439)),
                  fontSize: 15.sp,
                ),
              ),
              SizedBox(width: 4.w),
              Icon(
                expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 17.sp,
                color: context.inkColor(const Color(0xFFA4B35E)),
              ),
              const Spacer(),
              _MonthArrow(icon: Icons.chevron_left_rounded),
              SizedBox(width: 7.w),
              _MonthArrow(icon: Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
      AnimatedSize(
        duration: const Duration(milliseconds: 180),
        child: expanded
            ? Padding(
                padding: EdgeInsets.only(top: 10.h),
                child: Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: context.surfaceColor(Colors.white),
                    borderRadius: BorderRadius.circular(24.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .06),
                        blurRadius: 20.r,
                        offset: Offset(0, 6.h),
                      ),
                    ],
                  ),
                  child: const _MonthWheel(),
                ),
              )
            : const SizedBox.shrink(),
      ),
    ],
  );
}

class _MonthArrow extends StatelessWidget {
  const _MonthArrow({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 27.r,
    height: 27.r,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: context.surfaceColor(Colors.white),
      borderRadius: BorderRadius.circular(8.r),
      border: Border.all(color: context.lineColor(const Color(0xFFE3EBCE))),
    ),
    child: Icon(
      icon,
      size: 17.sp,
      color: context.inkColor(const Color(0xFF596439)),
    ),
  );
}

class _MonthWheel extends StatelessWidget {
  const _MonthWheel();

  @override
  Widget build(BuildContext context) {
    const months = ['June', 'July', 'August', 'September', 'October'];
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              for (final month in months)
                Container(
                  height: 27.h,
                  alignment: Alignment.center,
                  decoration: month == 'August'
                      ? BoxDecoration(
                          color: context.surfaceColor(const Color(0xFFF0F4E6)),
                          borderRadius: BorderRadius.circular(8.r),
                        )
                      : null,
                  child: Text(
                    month,
                    style: TextStyle(
                      color: context.textInkColor(
                        month == 'August'
                            ? const Color(0xFF20211E)
                            : const Color(0xFF95A08F),
                      ),
                      fontSize: month == 'August' ? 18.sp : 14.sp,
                      fontWeight: month == 'August'
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              for (final year in const ['2026', '2026', '2026', '2026', '2026'])
                SizedBox(
                  height: 27.h,
                  child: Center(
                    child: Text(
                      year,
                      style: TextStyle(
                        color: context.textInkColor(const Color(0xFF5F677A)),
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({required this.selectedDay, required this.onDayChanged});

  final int selectedDay;
  final ValueChanged<int> onDayChanged;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          for (final label in const [
            'Fri',
            'Sat',
            'Sun',
            'Mon',
            'Tue',
            'Wed',
            'Thu',
          ])
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: label == 'Wed'
                      ? context.textInkColor(const Color(0xFF292A27))
                      : context.textInkColor(const Color(0xFF989A92)),
                  fontSize: 9.sp,
                  fontWeight: label == 'Wed'
                      ? FontWeight.w700
                      : FontWeight.w400,
                ),
              ),
            ),
        ],
      ),
      SizedBox(height: 8.h),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 31,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          mainAxisSpacing: 8.h,
          crossAxisSpacing: 8.w,
        ),
        itemBuilder: (context, index) {
          final day = index + 1;
          final selected = day == selectedDay;
          return InkWell(
            onTap: () => onDayChanged(day),
            borderRadius: BorderRadius.circular(11.r),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.surfaceColor(
                  selected ? const Color(0xFFA9B75A) : const Color(0xFFE2ECB8),
                ),
                borderRadius: BorderRadius.circular(11.r),
              ),
              child: Text(
                '$day',
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : context.textInkColor(const Color(0xFF626950)),
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    ],
  );
}

class _HistorySummaryData {
  const _HistorySummaryData({
    required this.date,
    required this.count,
    this.items = const [],
  });

  final String date;
  final String count;
  final List<_RecitationCardData> items;
}

const _weeklySummaries = [
  _HistorySummaryData(date: '23.10.26', count: '04'),
  _HistorySummaryData(date: '24.10.26', count: '01'),
  _HistorySummaryData(date: '25.10.26', count: '07'),
  _HistorySummaryData(
    date: '26.10.26',
    count: '02',
    items: [
      _RecitationCardData(
        title: 'Added DUA names here..',
        category: 'Category name here',
        arabic: 'Arabic dua here . . . .',
        surface: Color(0xFFFFE9E2),
        accent: Color(0xFFFF604D),
      ),
      _RecitationCardData(
        title: 'Added DUA names here..',
        category: 'Category name here',
        arabic: 'Arabic dua here . . . .',
        surface: Color(0xFFFFF3D4),
        accent: Color(0xFFE9A51C),
      ),
    ],
  ),
  _HistorySummaryData(date: '28.10.26', count: '00'),
  _HistorySummaryData(date: '29.10.26', count: '00'),
];

class _HistorySummary extends StatelessWidget {
  const _HistorySummary({
    required this.summary,
    required this.expanded,
    required this.onTap,
    this.muted = false,
  });

  final _HistorySummaryData summary;
  final bool expanded;
  final VoidCallback onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Opacity(
        opacity: muted ? .45 : 1,
        child: Material(
          color: context.surfaceColor(Colors.white),
          borderRadius: BorderRadius.circular(22.r),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22.r),
            child: Container(
              height: 68.h,
              padding: EdgeInsets.symmetric(horizontal: 18.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .045),
                    blurRadius: 16.r,
                    offset: Offset(0, 5.h),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    summary.date,
                    style: TextStyle(
                      color: context.textInkColor(const Color(0xFF292A28)),
                      fontSize: 17.sp,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Reeded Dua',
                    style: TextStyle(
                      color: context.textInkColor(const Color(0xFF242521)),
                      fontFamily: 'serif',
                      fontSize: 18.sp,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    summary.count,
                    style: TextStyle(
                      color: context.textInkColor(const Color(0xFF292A28)),
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(width: 20.w),
                  Container(
                    width: 29.r,
                    height: 29.r,
                    decoration: BoxDecoration(
                      color: context.surfaceColor(const Color(0xFFE0EBB3)),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 19.sp,
                      color: context.inkColor(const Color(0xFF62703D)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      AnimatedSize(
        duration: const Duration(milliseconds: 180),
        child: expanded && summary.items.isNotEmpty
            ? Padding(
                padding: EdgeInsets.only(left: 33.w, top: 10.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 1.w,
                      height: 132.h,
                      color: context.lineColor(const Color(0xFFD8E8A7)),
                    ),
                    SizedBox(width: 24.w),
                    Expanded(
                      child: Column(
                        children: [
                          for (final item in summary.items) ...[
                            _RecitationCard(data: item),
                            if (item != summary.items.last)
                              SizedBox(height: 9.h),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              )
            : const SizedBox.shrink(),
      ),
    ],
  );
}
