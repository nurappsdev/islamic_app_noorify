import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/localization/localization_context.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/features/dua/data/models/dua_reading_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/domain/repositories/dua_repository.dart';
import 'package:tuhfatul_muslim/features/dua/dua_dependencies.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/dua_route_args.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_item_tile.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_status_view.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_responsive.dart';

/// Full recitation-history flow opened from the Dua dashboard's "See All"
/// action. Its Daily, Weekly, and Monthly views follow `devImg/img_30.png`
/// through `img_34.png`, backed by `GET /duas/reading/history`.
///
/// Tapping any recitation row reopens that dua in [DuaReaderScreen]; the
/// history is refreshed on the way back, so the row reflects the reading
/// that just happened.
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

  /// Anchor for the Daily and Weekly views' seven-day window, which ends
  /// today rather than following the calendar week. Held in state so tapping
  /// a day in the strip moves the selection without sliding the window along
  /// with it.
  late final DateTime _today = _dateOnly(DateTime.now());
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

  /// Opens [item]'s dua in the reader.
  ///
  /// A history row carries only the dua's id, title and Arabic, so the full
  /// dua is fetched first: the reader needs its `categoryId` for swipe
  /// navigation and its translation for the first frame. Returning from the
  /// reader refreshes the history, which the reading just changed.
  Future<void> _openDua(DuaReadingHistoryItem item) async {
    if (item.duaId.isEmpty) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final failureText = AppText.of(context).duaOpenFailed;
    try {
      final dua = await _repository.getDuaById(item.duaId);
      if (!mounted) return;
      await navigator.pushNamed(
        RouteNames.duaReader,
        arguments: DuaReaderArgs.real(dua),
      );
      if (!mounted) return;
      await _load(refresh: true);
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(failureText)));
    }
  }

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
                            today: _today,
                            items: _items,
                            loadingMore: _loadingMore,
                            onDateChanged: (date) =>
                                setState(() => _selectedDate = _dateOnly(date)),
                            onOpenDua: _openDua,
                          ),
                          _RecitationPeriod.weekly => _WeeklyHistory(
                            key: const ValueKey('weekly-history'),
                            selectedDate: _selectedDate,
                            today: _today,
                            items: _items,
                            loadingMore: _loadingMore,
                            expandedDates: _expandedDates,
                            onDateChanged: (date) =>
                                setState(() => _selectedDate = _dateOnly(date)),
                            onToggle: _toggleDate,
                            onOpenDua: _openDua,
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
                            onOpenDua: _openDua,
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
  String label(AppText text) => switch (this) {
    _RecitationPeriod.daily => text.daily,
    _RecitationPeriod.weekly => text.weekly,
    _RecitationPeriod.monthly => text.monthly,
  };
}

class _HistoryTopBar extends StatelessWidget {
  const _HistoryTopBar({required this.period, required this.onPeriodChanged});

  final _RecitationPeriod period;
  final ValueChanged<_RecitationPeriod> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Padding(
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
                            item.label(appText),
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
        ],
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

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

/// The Daily view: one day's recitations on a timeline, with the same
/// seven-day strip the Weekly view runs on — the six days before today and
/// then today last (16 → 22 on the 22nd).
class _DailyHistory extends StatelessWidget {
  const _DailyHistory({
    super.key,
    required this.selectedDate,
    required this.today,
    required this.items,
    required this.loadingMore,
    required this.onDateChanged,
    required this.onOpenDua,
  });

  final DateTime selectedDate;
  final DateTime today;
  final List<DuaReadingHistoryItem> items;
  final bool loadingMore;
  final ValueChanged<DateTime> onDateChanged;
  final _OpenDua onOpenDua;

  @override
  Widget build(BuildContext context) {
    final selectedItems = _itemsOn(items, selectedDate);
    final times = context.localizedTimes;
    final byTime = <String, List<DuaReadingHistoryItem>>{};
    for (final item in selectedItems) {
      final time = item.lastReadAt?.toLocal();
      final label = time == null ? '—' : times.clockOf(time);
      byTime.putIfAbsent(label, () => []).add(item);
    }
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      // Centred and capped on a wide browser; unchanged on a phone.
      padding: duaPagePadding(
        context,
        left: 16.w,
        top: 10.h,
        right: 10.w,
        bottom: 24.h,
      ),
      children: [
        const _HistoryTitle(),
        SizedBox(height: 22.h),
        _WeekStrip(
          days: _trailingWeek(today),
          selectedDate: selectedDate,
          onDateChanged: onDateChanged,
        ),
        SizedBox(height: 22.h),
        if (selectedItems.isEmpty) const _EmptyHistory(),
        for (final entry in byTime.entries)
          _TimelineGroup(
            time: entry.key,
            items: entry.value,
            onOpenDua: onOpenDua,
          ),
        if (loadingMore) const _HistoryLoadingMore(),
      ],
    );
  }
}

class _HistoryTitle extends StatelessWidget {
  const _HistoryTitle();

  @override
  Widget build(BuildContext context) => Text(
    AppText.of(context).duaRecitationHistoryTitle,
    style: TextStyle(
      color: context.textInkColor(const Color(0xFFA3B35E)),
      fontFamily: 'serif',
      fontSize: 24.sp,
      fontWeight: FontWeight.w700,
      fontStyle: FontStyle.italic,
    ),
  );
}

/// The seven-day strip above the Daily and Weekly lists. The days it shows
/// are chosen by the caller, so the strip only draws them.
class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.days,
    required this.selectedDate,
    required this.onDateChanged,
  });

  final List<DateTime> days;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  @override
  Widget build(BuildContext context) {
    final dates = context.localizedDates;
    final numbers = context.localizedNumbers;
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
                    // Sunday-first, the order the strip itself runs in.
                    dates.weekdayShort(day.weekday % 7),
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
                      numbers.integer(day.day),
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
  const _TimelineGroup({
    required this.time,
    required this.items,
    required this.onOpenDua,
  });

  final String time;
  final List<DuaReadingHistoryItem> items;
  final _OpenDua onOpenDua;

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
              for (var index = 0; index < items.length; index++) ...[
                _RecitationCard(
                  item: items[index],
                  index: index,
                  onOpenDua: onOpenDua,
                ),
                if (index != items.length - 1) SizedBox(height: 10.h),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

/// Opens a recitation row's dua in the reader; completes once the reader
/// has been closed again.
typedef _OpenDua = Future<void> Function(DuaReadingHistoryItem item);

/// One recitation row, drawn as the numbered [DuaItemTile] a category's dua
/// list uses, so a dua reads the same here as where it was opened from.
///
/// Tapping it reopens the dua in the reader; while the dua is being fetched
/// the row's chevron becomes a spinner, and a second tap is ignored until
/// that finishes.
class _RecitationCard extends StatefulWidget {
  const _RecitationCard({
    required this.item,
    required this.index,
    required this.onOpenDua,
  });

  final DuaReadingHistoryItem item;

  /// Position in its day or time group (0-based) — the tile's number and its
  /// pastel colour both come from this.
  final int index;

  final _OpenDua onOpenDua;

  @override
  State<_RecitationCard> createState() => _RecitationCardState();
}

class _RecitationCardState extends State<_RecitationCard> {
  bool _opening = false;

  Future<void> _open() async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      await widget.onOpenDua(widget.item);
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = context.localized(widget.item.title);
    // The dua's own words make the preview line, as the translation does in
    // a category's list; a row without Arabic falls back to its category so
    // the line is never left blank.
    final arabic = widget.item.arabic.trim();
    final category = context.localized(widget.item.category);
    return DuaItemTile(
      index: widget.index,
      name: title.isEmpty ? '—' : title,
      subtitle: arabic.isEmpty ? category : arabic,
      busy: _opening,
      onTap: widget.item.duaId.isEmpty ? null : _open,
    );
  }
}

/// The Weekly view. Its week is the last seven days, not a calendar week, so
/// it never runs on into days that have not happened yet. The strip at the
/// top reads oldest first and ends on today
/// (16 → 22 on the 22nd); the day cards below it run the other way, today
/// at the top down to a week ago at the bottom.
class _WeeklyHistory extends StatelessWidget {
  const _WeeklyHistory({
    super.key,
    required this.selectedDate,
    required this.today,
    required this.items,
    required this.loadingMore,
    required this.expandedDates,
    required this.onDateChanged,
    required this.onToggle,
    required this.onOpenDua,
  });

  final DateTime selectedDate;
  final DateTime today;
  final List<DuaReadingHistoryItem> items;
  final bool loadingMore;
  final Set<String> expandedDates;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<String> onToggle;
  final _OpenDua onOpenDua;

  @override
  Widget build(BuildContext context) {
    final days = _trailingWeek(today);
    // The strip reads forward and ends on today, while the list below leads
    // with today and works back, so the reading that just happened is the
    // first card rather than the last.
    final summaries = _summariesForDays(items, days.reversed);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      // Centred and capped on a wide browser; unchanged on a phone.
      padding: duaPagePadding(
        context,
        left: 16.w,
        top: 10.h,
        right: 10.w,
        bottom: 24.h,
      ),
      children: [
        const _HistoryTitle(),
        SizedBox(height: 22.h),
        _WeekStrip(
          days: days,
          selectedDate: selectedDate,
          onDateChanged: onDateChanged,
        ),
        SizedBox(height: 16.h),
        for (final summary in summaries) ...[
          _HistorySummary(
            summary: summary,
            expanded: expandedDates.contains(summary.id),
            onTap: () => onToggle(summary.id),
            onOpenDua: onOpenDua,
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
    required this.onOpenDua,
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
  final _OpenDua onOpenDua;

  @override
  Widget build(BuildContext context) {
    final summaries = _summariesForMonth(items, selectedDate);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      // Centred and capped on a wide browser; unchanged on a phone.
      padding: duaPagePadding(
        context,
        left: 16.w,
        top: 10.h,
        right: 10.w,
        bottom: 24.h,
      ),
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
            onOpenDua: onOpenDua,
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
                context.localizedDates.monthYear(month),
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
                context.localizedDates.monthYear(item),
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
                context.localizedNumbers.integer(item.year),
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
    final dates = context.localizedDates;
    final numbers = context.localizedNumbers;
    // The grid below starts each month on its Sunday column, so the header
    // counts from Sunday too; the selected day's own column is the one that
    // stands out.
    final selectedColumn = selectedDate.weekday % 7;
    return Column(
      children: [
        Row(
          children: [
            for (var column = 0; column < DateTime.daysPerWeek; column++)
              Expanded(
                child: Text(
                  dates.weekdayShort(column),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: column == selectedColumn
                        ? context.textInkColor(const Color(0xFF292A27))
                        : context.textInkColor(const Color(0xFF989A92)),
                    fontSize: 9.sp,
                    fontWeight: column == selectedColumn
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
                  numbers.integer(date.day),
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
    required this.onOpenDua,
  });

  final _HistorySummaryData summary;
  final bool expanded;
  final VoidCallback onTap;
  final _OpenDua onOpenDua;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Column(
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
              // The date and the label share the row's width instead of
              // being pushed apart by spacers: a Bangla date is written out
              // in full (`২২ নভেম্বর ২০২৬`), which overflowed the fixed
              // layout this row had.
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.localizedDates.gregorian(
                        summary.date,
                        shortMonth: true,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.textInkColor(const Color(0xFF292A28)),
                        fontSize: 17.sp,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      appText.duaReadDuaLabel,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.textInkColor(const Color(0xFF242521)),
                        fontFamily: 'serif',
                        fontSize: 18.sp,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    context.localizedNumbers.digits(
                      '${summary.items.length}'.padLeft(2, '0'),
                    ),
                    style: TextStyle(
                      color: context.textInkColor(const Color(0xFF292A28)),
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
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
                                index: index,
                                onOpenDua: onOpenDua,
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

/// The week ending on [today]: six days back first, up to today last (16 →
/// 22 on the 22nd). The Weekly view runs on this so it ends on today instead
/// of carrying on into days that are still to come.
List<DateTime> _trailingWeek(DateTime today) {
  final firstDay = _dateOnly(today).subtract(const Duration(days: 6));
  return List.generate(
    7,
    (index) => firstDay.add(Duration(days: index)),
    growable: false,
  );
}

/// One summary per day of [days], in the order [days] runs in.
List<_HistorySummaryData> _summariesForDays(
  List<DuaReadingHistoryItem> items,
  Iterable<DateTime> days,
) => [
  for (final date in days)
    _HistorySummaryData(
      id: date.toIso8601String(),
      date: date,
      items: _itemsOn(items, date),
    ),
];

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
