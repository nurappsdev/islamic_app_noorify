import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/features/dua/data/models/dua_reading_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/domain/repositories/dua_repository.dart';
import 'package:tuhfatul_muslim/features/dua/dua_dependencies.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_status_view.dart';

/// Full recitation-history flow opened from the Dua dashboard's "See All"
/// action. Its Daily, Weekly, and Monthly views follow `devImg/img_30.png`
/// through `img_34.png`, backed by `GET /duas/reading/history`.
class DuaRecitationHistoryScreen extends StatefulWidget {
  const DuaRecitationHistoryScreen({super.key, this.repository});

  /// Injectable for tests; production uses the feature composition root.
  final DuaRepository? repository;

  @override
  State<DuaRecitationHistoryScreen> createState() =>
      _DuaRecitationHistoryScreenState();
}

class _DuaRecitationHistoryScreenState
    extends State<DuaRecitationHistoryScreen> {
  _RecitationPeriod _period = _RecitationPeriod.daily;
  final _expandedDates = <String>{};
  bool _monthPickerOpen = false;
  late final DuaRepository _repository = widget.repository ?? duaRepository;
  late DateTime _selectedDate = _dateOnly(DateTime.now());
  List<DuaReadingHistoryItem> _items = const [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _failed = false;
  int _page = 0;
  int _totalPage = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool refresh = false}) async {
    if (_loadingMore) return;
    setState(() {
      _loading = !refresh || _items.isEmpty;
      _failed = false;
    });
    try {
      final page = await _repository.getReadingHistory(page: 1, limit: 50);
      if (!mounted) return;
      setState(() {
        _items = page.items;
        _page = page.page;
        _totalPage = page.totalPage;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || _page >= _totalPage) return;
    setState(() => _loadingMore = true);
    try {
      final page = await _repository.getReadingHistory(
        page: _page + 1,
        limit: 50,
      );
      if (!mounted) return;
      setState(() {
        _items = [..._items, ...page.items];
        _page = page.page;
        _totalPage = page.totalPage;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _toggleDate(String date) => setState(() {
    if (!_expandedDates.add(date)) _expandedDates.remove(date);
  });

  /// Moves to [month], keeping the day of the month where it can.
  /// [closePicker] is for a tap on the wheel: a dropdown that has been
  /// chosen from closes, while the arrows leave it open to step through.
  void _changeMonth(DateTime month, {bool closePicker = false}) => setState(() {
    _selectedDate = DateTime(
      month.year,
      month.month,
      _selectedDate.day.clamp(1, _daysInMonth(month)),
    );
    if (closePicker) _monthPickerOpen = false;
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
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _failed
                ? DuaErrorRetry(
                    message: AppText.of(context).duaDashboardLoadFailed,
                    onRetry: _load,
                  )
                : RefreshIndicator(
                    onRefresh: () => _load(refresh: true),
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification.metrics.extentAfter < 240) _loadMore();
                        return false;
                      },
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: switch (_period) {
                          _RecitationPeriod.daily => _DailyHistory(
                            key: const ValueKey('daily-history'),
                            selectedDate: _selectedDate,
                            items: _items,
                            loadingMore: _loadingMore,
                            onDateChanged: (date) =>
                                setState(() => _selectedDate = _dateOnly(date)),
                          ),
                          _RecitationPeriod.weekly => _WeeklyHistory(
                            key: const ValueKey('weekly-history'),
                            selectedDate: _selectedDate,
                            items: _items,
                            loadingMore: _loadingMore,
                            expandedDates: _expandedDates,
                            onDateChanged: (date) =>
                                setState(() => _selectedDate = _dateOnly(date)),
                            onToggle: _toggleDate,
                          ),
                          _RecitationPeriod.monthly => _MonthlyHistory(
                            key: const ValueKey('monthly-history'),
                            selectedDate: _selectedDate,
                            items: _items,
                            loadingMore: _loadingMore,
                            monthPickerOpen: _monthPickerOpen,
                            expandedDates: _expandedDates,
                            onDateChanged: (date) =>
                                setState(() => _selectedDate = _dateOnly(date)),
                            onMonthPickerToggle: () => setState(
                              () => _monthPickerOpen = !_monthPickerOpen,
                            ),
                            onMonthChanged: _changeMonth,
                            onMonthPicked: (month) =>
                                _changeMonth(month, closePicker: true),
                            onToggle: _toggleDate,
                          ),
                        },
                      ),
                    ),
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
    required this.selectedDate,
    required this.items,
    required this.loadingMore,
    required this.onDateChanged,
  });

  final DateTime selectedDate;
  final List<DuaReadingHistoryItem> items;
  final bool loadingMore;
  final ValueChanged<DateTime> onDateChanged;

  @override
  Widget build(BuildContext context) {
    final selectedItems = _itemsOn(items, selectedDate);
    final byTime = <String, List<DuaReadingHistoryItem>>{};
    for (final item in selectedItems) {
      final time = item.lastReadAt?.toLocal();
      final label = time == null
          ? '—'
          : MaterialLocalizations.of(
              context,
            ).formatTimeOfDay(TimeOfDay.fromDateTime(time));
      byTime.putIfAbsent(label, () => []).add(item);
    }
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 10.w, 24.h),
      children: [
        const _HistoryTitle(),
        SizedBox(height: 22.h),
        _WeekStrip(selectedDate: selectedDate, onDateChanged: onDateChanged),
        SizedBox(height: 22.h),
        if (selectedItems.isEmpty) const _EmptyHistory(),
        for (final entry in byTime.entries)
          _TimelineGroup(time: entry.key, items: entry.value),
        if (loadingMore) const _HistoryLoadingMore(),
      ],
    );
  }
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
  const _WeekStrip({required this.selectedDate, required this.onDateChanged});

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  @override
  Widget build(BuildContext context) {
    final start = selectedDate.subtract(
      Duration(days: selectedDate.weekday % 7),
    );
    final days = List.generate(7, (index) => start.add(Duration(days: index)));
    return Row(
      children: [
        for (final day in days)
          Expanded(
            child: InkWell(
              onTap: () => onDateChanged(day),
              borderRadius: BorderRadius.circular(24.r),
              child: Column(
                children: [
                  Text(
                    MaterialLocalizations.of(
                      context,
                    ).narrowWeekdays[day.weekday % 7],
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: _sameDay(day, selectedDate)
                          ? context.textInkColor(const Color(0xFF2A2E27))
                          : context.textInkColor(const Color(0xFF8A8D85)),
                      fontWeight: _sameDay(day, selectedDate)
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
                        _sameDay(day, selectedDate)
                            ? const Color(0xFFA9B75A)
                            : const Color(0xFFE2ECB8),
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: _sameDay(day, selectedDate)
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
                      color: _sameDay(day, selectedDate)
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
}

class _TimelineGroup extends StatelessWidget {
  const _TimelineGroup({required this.time, required this.items});

  final String time;
  final List<DuaReadingHistoryItem> items;

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
              for (var index = 0; index < items.length; index++)
                _RecitationCard(item: items[index], colorIndex: index),
            ],
          ),
        ),
      ],
    ),
  );
}

class _RecitationCard extends StatelessWidget {
  const _RecitationCard({required this.item, required this.colorIndex});

  final DuaReadingHistoryItem item;
  final int colorIndex;

  @override
  Widget build(BuildContext context) {
    const surfaces = [
      Color(0xFFFFE9E2),
      Color(0xFFE9E7FF),
      Color(0xFFFFF3D4),
      Color(0xFFE6F4EC),
    ];
    const accents = [
      Color(0xFFFF604D),
      Color(0xFF5B54E8),
      Color(0xFFE9A51C),
      Color(0xFF4BA779),
    ];
    final surface = surfaces[colorIndex % surfaces.length];
    final accent = accents[colorIndex % accents.length];
    final title = context.localized(item.title);
    final category = context.localized(item.category);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: context.surfaceColor(surface),
        borderRadius: BorderRadius.circular(23.r),
        border: Border.all(color: context.lineColor(surface)),
      ),
      child: Row(
        children: [
          Container(
            width: 40.r,
            height: 40.r,
            decoration: BoxDecoration(
              color: context.surfaceColor(accent),
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
                  title.isEmpty ? '—' : title,
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
                    category.isEmpty ? '—' : category,
                    style: TextStyle(
                      color: context.textInkColor(const Color(0xFF4E4E4B)),
                      fontSize: 8.sp,
                    ),
                  ),
                ),
                SizedBox(height: 5.h),
                Text(
                  item.arabic,
                  style: TextStyle(
                    color: context.textInkColor(const Color(0xFF53534D)),
                    fontSize: 10.sp,
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

class _WeeklyHistory extends StatelessWidget {
  const _WeeklyHistory({
    super.key,
    required this.selectedDate,
    required this.items,
    required this.loadingMore,
    required this.expandedDates,
    required this.onDateChanged,
    required this.onToggle,
  });

  final DateTime selectedDate;
  final List<DuaReadingHistoryItem> items;
  final bool loadingMore;
  final Set<String> expandedDates;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final summaries = _summariesForWeek(items, selectedDate);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 10.w, 24.h),
      children: [
        const _HistoryTitle(),
        SizedBox(height: 22.h),
        _WeekStrip(selectedDate: selectedDate, onDateChanged: onDateChanged),
        SizedBox(height: 16.h),
        for (final summary in summaries) ...[
          _HistorySummary(
            summary: summary,
            expanded: expandedDates.contains(summary.id),
            onTap: () => onToggle(summary.id),
          ),
          SizedBox(height: 11.h),
        ],
        if (loadingMore) const _HistoryLoadingMore(),
      ],
    );
  }
}

class _MonthlyHistory extends StatelessWidget {
  const _MonthlyHistory({
    super.key,
    required this.selectedDate,
    required this.items,
    required this.loadingMore,
    required this.monthPickerOpen,
    required this.expandedDates,
    required this.onDateChanged,
    required this.onMonthPickerToggle,
    required this.onMonthChanged,
    required this.onMonthPicked,
    required this.onToggle,
  });

  final DateTime selectedDate;
  final List<DuaReadingHistoryItem> items;
  final bool loadingMore;
  final bool monthPickerOpen;
  final Set<String> expandedDates;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback onMonthPickerToggle;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onMonthPicked;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final summaries = _summariesForMonth(items, selectedDate);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 10.w, 24.h),
      children: [
        _MonthSelector(
          month: selectedDate,
          expanded: monthPickerOpen,
          onTap: onMonthPickerToggle,
          onPrevious: () => onMonthChanged(
            DateTime(selectedDate.year, selectedDate.month - 1),
          ),
          onNext: () => onMonthChanged(
            DateTime(selectedDate.year, selectedDate.month + 1),
          ),
          onMonthPicked: onMonthPicked,
        ),
        SizedBox(height: 10.h),
        _MonthCalendar(
          selectedDate: selectedDate,
          activeDays: summaries.map((summary) => summary.date).toSet(),
          onDateChanged: onDateChanged,
        ),
        SizedBox(height: 16.h),
        if (summaries.isEmpty) const _EmptyHistory(),
        for (final summary in summaries) ...[
          _HistorySummary(
            summary: summary,
            expanded: expandedDates.contains(summary.id),
            onTap: () => onToggle(summary.id),
          ),
          SizedBox(height: 11.h),
        ],
        if (loadingMore) const _HistoryLoadingMore(),
      ],
    );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.month,
    required this.expanded,
    required this.onTap,
    required this.onPrevious,
    required this.onNext,
    required this.onMonthPicked,
  });

  final DateTime month;
  final bool expanded;
  final VoidCallback onTap;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onMonthPicked;

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
                MaterialLocalizations.of(context).formatMonthYear(month),
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                  color: context.textInkColor(const Color(0xFF596439)),
                ),
              ),
              SizedBox(width: 4.w),
              Icon(
                expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 17.sp,
                color: context.inkColor(const Color(0xFFA4B35E)),
              ),
              const Spacer(),
              _MonthArrow(icon: Icons.chevron_left_rounded, onTap: onPrevious),
              SizedBox(width: 7.w),
              _MonthArrow(icon: Icons.chevron_right_rounded, onTap: onNext),
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
                  child: _MonthWheel(
                    month: month,
                    onMonthPicked: onMonthPicked,
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    ],
  );
}

class _MonthArrow extends StatelessWidget {
  const _MonthArrow({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8.r),
    child: Container(
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
    ),
  );
}

class _MonthWheel extends StatelessWidget {
  const _MonthWheel({required this.month, required this.onMonthPicked});

  final DateTime month;
  final ValueChanged<DateTime> onMonthPicked;

  @override
  Widget build(BuildContext context) {
    final months = List.generate(
      5,
      (index) => DateTime(month.year, month.month + index - 2),
    );
    return Column(
      children: [
        for (final item in months)
          _MonthWheelRow(
            item: item,
            selected: item.month == month.month && item.year == month.year,
            onTap: () => onMonthPicked(item),
          ),
      ],
    );
  }
}

/// One line of the wheel. The whole line answers a tap, so the year beside
/// the month name picks the same month rather than sitting there inert.
class _MonthWheelRow extends StatelessWidget {
  const _MonthWheelRow({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final DateTime item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8.r),
    child: SizedBox(
      height: 27.h,
      child: Row(
        children: [
          Expanded(
            child: Container(
              alignment: Alignment.center,
              decoration: selected
                  ? BoxDecoration(
                      color: context.surfaceColor(const Color(0xFFF0F4E6)),
                      borderRadius: BorderRadius.circular(8.r),
                    )
                  : null,
              child: Text(
                MaterialLocalizations.of(context).formatMonthYear(item),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.textInkColor(
                    selected
                        ? const Color(0xFF20211E)
                        : const Color(0xFF95A08F),
                  ),
                  fontSize: selected ? 18.sp : 14.sp,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                '${item.year}',
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
  );
}

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.selectedDate,
    required this.activeDays,
    required this.onDateChanged,
  });

  final DateTime selectedDate;
  final Set<DateTime> activeDays;
  final ValueChanged<DateTime> onDateChanged;

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(selectedDate.year, selectedDate.month);
    final startOffset = firstDay.weekday % 7;
    final totalCells = startOffset + _daysInMonth(selectedDate);
    return Column(
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
          itemCount: totalCells,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8.h,
            crossAxisSpacing: 8.w,
          ),
          itemBuilder: (context, index) {
            if (index < startOffset) return const SizedBox.shrink();
            final date = DateTime(
              selectedDate.year,
              selectedDate.month,
              index - startOffset + 1,
            );
            final selected = _sameDay(date, selectedDate);
            final active = activeDays.any((item) => _sameDay(item, date));
            return InkWell(
              onTap: () => onDateChanged(date),
              borderRadius: BorderRadius.circular(11.r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.surfaceColor(
                    selected
                        ? const Color(0xFFA9B75A)
                        : active
                        ? const Color(0xFFE2ECB8)
                        : const Color(0xFFF5F7EB),
                  ),
                  borderRadius: BorderRadius.circular(11.r),
                ),
                child: Text(
                  '${date.day}',
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
}

class _HistorySummaryData {
  const _HistorySummaryData({
    required this.id,
    required this.date,
    required this.items,
  });

  final String id;
  final DateTime date;
  final List<DuaReadingHistoryItem> items;
}

class _HistorySummary extends StatelessWidget {
  const _HistorySummary({
    required this.summary,
    required this.expanded,
    required this.onTap,
  });

  final _HistorySummaryData summary;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Material(
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
                  MaterialLocalizations.of(
                    context,
                  ).formatShortDate(summary.date),
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
                  '${summary.items.length}'.padLeft(2, '0'),
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
                          for (
                            var index = 0;
                            index < summary.items.length;
                            index++
                          ) ...[
                            _RecitationCard(
                              item: summary.items[index],
                              colorIndex: index,
                            ),
                            if (index != summary.items.length - 1)
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

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: 32.h),
    child: Text(
      AppText.of(context).duaNoRecitationHistory,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12.sp,
        color: context.textInkColor(const Color(0xFF778060)),
      ),
    ),
  );
}

class _HistoryLoadingMore extends StatelessWidget {
  const _HistoryLoadingMore();

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.all(16.r),
    child: const Center(child: CircularProgressIndicator()),
  );
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

bool _sameDay(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;

int _daysInMonth(DateTime value) =>
    DateTime(value.year, value.month + 1, 0).day;

List<DuaReadingHistoryItem> _itemsOn(
  List<DuaReadingHistoryItem> items,
  DateTime date,
) =>
    [
      for (final item in items)
        if (item.lastReadAt != null &&
            _sameDay(item.lastReadAt!.toLocal(), date))
          item,
    ]..sort(
      (left, right) => (left.lastReadAt ?? DateTime(0)).compareTo(
        right.lastReadAt ?? DateTime(0),
      ),
    );

List<_HistorySummaryData> _summariesForWeek(
  List<DuaReadingHistoryItem> items,
  DateTime selectedDate,
) {
  final firstDay = _dateOnly(
    selectedDate.subtract(Duration(days: selectedDate.weekday % 7)),
  );
  return List.generate(7, (index) {
    final date = firstDay.add(Duration(days: index));
    return _HistorySummaryData(
      id: date.toIso8601String(),
      date: date,
      items: _itemsOn(items, date),
    );
  }).reversed.toList(growable: false);
}

List<_HistorySummaryData> _summariesForMonth(
  List<DuaReadingHistoryItem> items,
  DateTime selectedDate,
) {
  final summaries = <_HistorySummaryData>[];
  for (var day = 1; day <= _daysInMonth(selectedDate); day++) {
    final date = DateTime(selectedDate.year, selectedDate.month, day);
    final dayItems = _itemsOn(items, date);
    if (dayItems.isNotEmpty) {
      summaries.add(
        _HistorySummaryData(
          id: date.toIso8601String(),
          date: date,
          items: dayItems,
        ),
      );
    }
  }
  return summaries.reversed.toList(growable: false);
}
