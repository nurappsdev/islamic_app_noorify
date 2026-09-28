import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hijri/hijri_calendar.dart';

import 'package:islami_app_noorify/core/theme/app_palette.dart';
import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/core/utils/localized_text.dart';
import 'package:islami_app_noorify/features/home/data/services/prayer_time_service.dart';
import 'package:islami_app_noorify/features/home/domain/calendar/bangla_date.dart';
import 'package:islami_app_noorify/features/home/presentation/screens/home_screen.dart';
import 'package:islami_app_noorify/core/localization/localized_date_formatter.dart';
import 'package:islami_app_noorify/core/localization/localized_number_formatter.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_state.dart';

enum _CalTab { bangla, arabic, english }

const _banglaDigits = LocalizedNumberFormatter.banglaDigits;
const _arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

/// Western digits in [value] mapped through [digits] (Bangla/Arabic-Indic);
/// `null` leaves western digits untouched.
String _localizeDigits(int value, List<String>? digits) {
  if (digits == null) return '$value';
  return '$value'.split('').map((c) => digits[int.parse(c)]).join();
}

const _hijriMonthNamesAr = [
  'محرم',
  'صفر',
  'ربيع الأول',
  'ربيع الآخر',
  'جمادى الأولى',
  'جمادى الآخرة',
  'رجب',
  'شعبان',
  'رمضان',
  'شوال',
  'ذو القعدة',
  'ذو الحجة',
];

const _hijriWeekdayShortAr = [
  'أحد',
  'اثنين',
  'ثلاثاء',
  'أربعاء',
  'خميس',
  'جمعة',
  'سبت',
];

const _weekdayFullAr = [
  'الأحد',
  'الاثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة',
  'السبت',
];

const _weekdayShortEn = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

class _CalCell {
  const _CalCell({
    required this.day,
    required this.inMonth,
    required this.isToday,
  });

  final int day;
  final bool inMonth;
  final bool isToday;
}

/// The Bangla / Arabic / English calendar card shown on the home screen,
/// right after the Qiblah compass card. Each tab is its own native calendar
/// system, not a relabeled Gregorian grid:
/// - Bangla: the Bengali solar calendar, plus today's Hijri date written in
///   Bangla script underneath.
/// - Arabic: the Hijri lunar calendar, shown either in Arabic script and
///   digits or, by tapping the selected Arabic tab again, in its Bangla form.
/// - English: the plain Gregorian calendar.
class HomeCalendarCard extends StatefulWidget {
  const HomeCalendarCard({super.key});

  @override
  State<HomeCalendarCard> createState() => _HomeCalendarCardState();
}

class _HomeCalendarCardState extends State<HomeCalendarCard> {
  _CalTab _tab = _CalTab.english;

  /// Arabic tab only: show the Hijri calendar in Bangla (month names, digits,
  /// weekdays) instead of Arabic script. Flipped by tapping the Arabic tab while
  /// it is already selected (see [_TabRow]).
  bool _arabicInBangla = false;

  late int _enYear;
  late int _enMonth;
  late int _bnYear;
  late int _bnMonth;
  late int _hYear;
  late int _hMonth;

  late final DateTime _todayEn;
  late final BanglaDate _todayBn;
  // Today's Hijri date. It moves to the next day at Maghrib, so it is
  // refreshed once Maghrib is known (see [_loadMaghrib]).
  late int _todayHYear;
  late int _todayHMonth;
  late int _todayHDay;

  final _hijri = HijriCalendar();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _todayEn = DateTime(now.year, now.month, now.day);
    _enYear = _todayEn.year;
    _enMonth = _todayEn.month;

    _todayBn = BanglaDate.fromGregorian(now);
    _bnYear = _todayBn.year;
    _bnMonth = _todayBn.month;

    final hc = localHijriDate(bangladeshNow());
    _todayHYear = hc.hYear;
    _todayHMonth = hc.hMonth;
    _todayHDay = hc.hDay;
    _hYear = hc.hYear;
    _hMonth = hc.hMonth;
    _loadMaghrib();
  }

  /// Re-derives today's Hijri date once today's Maghrib is known. It comes
  /// from the on-device prayer-times cache, so no network call is made.
  Future<void> _loadMaghrib() async {
    try {
      final now = bangladeshNow();
      final service = await AladhanPrayerTimeService.create();
      final maghrib = service.cachedPrayerTimes(now)?.maghrib;
      if (!mounted || maghrib == null) return;
      final hc = localHijriDate(now, maghrib: maghrib);
      setState(() {
        // Keep the month being viewed unless the user is still on today's.
        if (_hYear == _todayHYear && _hMonth == _todayHMonth) {
          _hYear = hc.hYear;
          _hMonth = hc.hMonth;
        }
        _todayHYear = hc.hYear;
        _todayHMonth = hc.hMonth;
        _todayHDay = hc.hDay;
      });
    } catch (_) {
      // Keeps the date without the Maghrib adjustment.
    }
  }

  List<String>? get _digits => switch (_tab) {
    _CalTab.bangla => _banglaDigits,
    _CalTab.arabic => _arabicInBangla ? _banglaDigits : _arabicDigits,
    _CalTab.english => null,
  };

  TextDirection get _textDirection => _tab == _CalTab.arabic && !_arabicInBangla
      ? TextDirection.rtl
      : TextDirection.ltr;

  int get _year => switch (_tab) {
    _CalTab.english => _enYear,
    _CalTab.bangla => _bnYear,
    _CalTab.arabic => _hYear,
  };

  int get _month => switch (_tab) {
    _CalTab.english => _enMonth,
    _CalTab.bangla => _bnMonth,
    _CalTab.arabic => _hMonth,
  };

  List<String> get _monthNames => switch (_tab) {
    _CalTab.english => AppText.forLanguage(AppLanguage.english).monthNames,
    _CalTab.bangla => BanglaDate.monthNames,
    _CalTab.arabic =>
      _arabicInBangla
          ? LocalizedDateFormatter.hijriMonthNamesBn
          : _hijriMonthNamesAr,
  };

  List<String> get _weekdayShort => switch (_tab) {
    _CalTab.english => _weekdayShortEn,
    _CalTab.bangla => BanglaDate.weekdayShortNames,
    _CalTab.arabic =>
      _arabicInBangla ? BanglaDate.weekdayShortNames : _hijriWeekdayShortAr,
  };

  /// Today's date written in this tab's own calendar system and script.
  String _primaryTodayLine() {
    final wIdx = _todayEn.weekday % 7; // Sun=0..Sat=6, shared 7-day week.
    switch (_tab) {
      case _CalTab.english:
        // This tab is the English calendar whatever the app language is.
        return LocalizedDateFormatter(
          AppLanguage.english,
        ).gregorian(_todayEn, withWeekday: true);
      case _CalTab.bangla:
        final d = _localizeDigits(_todayBn.day, _banglaDigits);
        final y = _localizeDigits(_todayBn.year, _banglaDigits);
        return '${LocalizedDateFormatter(AppLanguage.bangla).weekdayName(_todayEn)}, $d '
            '${BanglaDate.monthNames[_todayBn.month - 1]} $y';
      case _CalTab.arabic:
        if (_arabicInBangla) {
          final d = _localizeDigits(_todayHDay, _banglaDigits);
          final y = _localizeDigits(_todayHYear, _banglaDigits);
          return '${LocalizedDateFormatter(AppLanguage.bangla).weekdayName(_todayEn)}, $d '
              '${LocalizedDateFormatter.hijriMonthNamesBn[_todayHMonth - 1]} $y';
        }
        final d = _localizeDigits(_todayHDay, _arabicDigits);
        final y = _localizeDigits(_todayHYear, _arabicDigits);
        return '${_weekdayFullAr[wIdx]}، $d '
            '${_hijriMonthNamesAr[_todayHMonth - 1]} $y';
    }
  }

  /// Today's Hijri date written in Bangla script — shown only under the
  /// Bangla tab.
  String _hijriInBangla() {
    final d = _localizeDigits(_todayHDay, _banglaDigits);
    final y = _localizeDigits(_todayHYear, _banglaDigits);
    return '${AppText.forLanguage(AppLanguage.bangla).hijriSuffix}: $d '
        '${LocalizedDateFormatter.hijriMonthNamesBn[_todayHMonth - 1]} $y';
  }

  List<_CalCell> _buildGenericCells({
    required int daysInMonth,
    required int firstWeekday, // Dart weekday: Mon=1..Sun=7
    required int prevMonthDays,
    required bool Function(int day) isToday,
  }) {
    final leading = firstWeekday % 7; // Sun=0..Sat=6
    final cells = <_CalCell>[];
    for (var i = 0; i < leading; i++) {
      cells.add(
        _CalCell(
          day: prevMonthDays - leading + 1 + i,
          inMonth: false,
          isToday: false,
        ),
      );
    }
    for (var d = 1; d <= daysInMonth; d++) {
      cells.add(_CalCell(day: d, inMonth: true, isToday: isToday(d)));
    }
    final remainder = cells.length % 7;
    if (remainder != 0) {
      for (var i = 0; i < 7 - remainder; i++) {
        cells.add(_CalCell(day: i + 1, inMonth: false, isToday: false));
      }
    }
    return cells;
  }

  /// The Gregorian day the local (Bangladesh) Hijri month begins on: the
  /// package's Saudi-based start, shifted by [hijriLocalOffsetDays].
  DateTime _localHijriMonthStart(int year, int month) {
    final start = _hijri.hijriToGregorian(year, month, 1);
    return DateTime(start.year, start.month, start.day - hijriLocalOffsetDays);
  }

  List<_CalCell> _buildCells() {
    switch (_tab) {
      case _CalTab.english:
        return _buildGenericCells(
          daysInMonth: DateTime(_enYear, _enMonth + 1, 0).day,
          firstWeekday: DateTime(_enYear, _enMonth, 1).weekday,
          prevMonthDays: DateTime(_enYear, _enMonth, 0).day,
          isToday: (d) =>
              _enYear == _todayEn.year &&
              _enMonth == _todayEn.month &&
              d == _todayEn.day,
        );
      case _CalTab.bangla:
        final prevMonth = _bnMonth == 1 ? 12 : _bnMonth - 1;
        final prevYear = _bnMonth == 1 ? _bnYear - 1 : _bnYear;
        return _buildGenericCells(
          daysInMonth: BanglaDate.daysInMonth(_bnYear, _bnMonth),
          firstWeekday: BanglaDate.toGregorian(_bnYear, _bnMonth, 1).weekday,
          prevMonthDays: BanglaDate.daysInMonth(prevYear, prevMonth),
          isToday: (d) =>
              _bnYear == _todayBn.year &&
              _bnMonth == _todayBn.month &&
              d == _todayBn.day,
        );
      case _CalTab.arabic:
        try {
          final prevMonth = _hMonth == 1 ? 12 : _hMonth - 1;
          final prevYear = _hMonth == 1 ? _hYear - 1 : _hYear;
          return _buildGenericCells(
            daysInMonth: _hijri.getDaysInMonth(_hYear, _hMonth),
            firstWeekday: _localHijriMonthStart(_hYear, _hMonth).weekday,
            prevMonthDays: _hijri.getDaysInMonth(prevYear, prevMonth),
            isToday: (d) =>
                _hYear == _todayHYear &&
                _hMonth == _todayHMonth &&
                d == _todayHDay,
          );
        } catch (_) {
          // Umm al-Qura data only covers 1356-1500 AH; outside that, show
          // an empty grid instead of crashing.
          return const [];
        }
    }
  }

  void _setMonth(int month) => setState(() {
    switch (_tab) {
      case _CalTab.english:
        _enMonth = month;
      case _CalTab.bangla:
        _bnMonth = month;
      case _CalTab.arabic:
        _hMonth = month;
    }
  });

  void _setYear(int year) => setState(() {
    switch (_tab) {
      case _CalTab.english:
        _enYear = year;
      case _CalTab.bangla:
        _bnYear = year;
      case _CalTab.arabic:
        _hYear = year;
    }
  });

  /// The Arabic tab doubles as the Arabic <-> Bangla toggle: tapping it while
  /// it is already showing flips the Hijri calendar's display language. The
  /// date itself doesn't change. Any other tap just switches tabs.
  void _onTabTapped(_CalTab tapped) => setState(() {
    if (tapped == _CalTab.arabic && _tab == _CalTab.arabic) {
      _arabicInBangla = !_arabicInBangla;
    }
    _tab = tapped;
  });

  Future<void> _pickMonth() async {
    final names = _monthNames;
    final current = _month;
    final selected = await showModalBottomSheet<int>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: names.length,
          itemBuilder: (context, index) => ListTile(
            title: Text(
              context.localizedDigits(names[index]),
              textDirection: _textDirection,
            ),
            trailing: index + 1 == current
                ? const Icon(Icons.check, color: AppColor.primary)
                : null,
            onTap: () => Navigator.of(sheetContext).pop(index + 1),
          ),
        ),
      ),
    );
    if (selected != null) _setMonth(selected);
  }

  /// Year list for the active calendar: this year, then the years after it
  /// (2026, 2027, 2028, ...). Hijri stops at 1500 AH, the end of the
  /// Umm al-Qura data.
  List<int> get _selectableYears {
    final first = switch (_tab) {
      _CalTab.english => _todayEn.year,
      _CalTab.bangla => _todayBn.year,
      _CalTab.arabic => _todayHYear,
    };
    final last = _tab == _CalTab.arabic ? 1500 : first + 50;
    final current = _year;
    return [
      // Keep an already-selected earlier year in the list.
      if (current < first) current,
      for (var y = first; y <= last; y++) y,
    ];
  }

  Future<void> _pickYear() async {
    final years = _selectableYears;
    final current = _year;
    const itemExtent = 56.0;
    final currentIndex = years.indexOf(current).clamp(0, years.length - 1);
    final selected = await showModalBottomSheet<int>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * .5,
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemExtent: itemExtent,
            controller: ScrollController(
              initialScrollOffset: currentIndex * itemExtent,
            ),
            itemCount: years.length,
            itemBuilder: (context, index) => ListTile(
              title: Text(
                _localizeDigits(years[index], _digits),
                textAlign: TextAlign.center,
              ),
              selected: years[index] == current,
              trailing: years[index] == current
                  ? const Icon(Icons.check, color: AppColor.primary)
                  : null,
              onTap: () => Navigator.of(sheetContext).pop(years[index]),
            ),
          ),
        ),
      ),
    );
    if (selected != null) _setYear(selected);
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final showBanglaHijriLine = _tab == _CalTab.bangla;
    return HomeCard(
      padding: EdgeInsets.all(12.w),
      shadows: [
        BoxShadow(
          color: const Color(0xFF8D9B70).withValues(alpha: .22),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
      child: Column(
        children: [
          _TabRow(
            tab: _tab,
            banglaLabel: appText.bangla,
            arabicLabel: appText.quranArabicLabel,
            englishLabel: appText.english,
            arabicInBangla: _arabicInBangla,
            onChanged: _onTabTapped,
          ),
          SizedBox(height: 12.h),
          Text(
            _primaryTodayLine(),
            textDirection: _textDirection,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: context.inkColor(const Color(0xFF2A331C)),
            ),
          ),
          if (showBanglaHijriLine) ...[
            SizedBox(height: 2.h),
            Text(
              _hijriInBangla(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: AppColor.primary,
              ),
            ),
          ],
          SizedBox(height: 10.h),
          _MonthYearRow(
            yearLabel: _localizeDigits(_year, _digits),
            monthName: _monthNames[_month - 1],
            textDirection: _textDirection,
            onTapYear: _pickYear,
            onTapMonth: _pickMonth,
          ),
          SizedBox(height: 14.h),
          _WeekdayHeader(labels: _weekdayShort),
          SizedBox(height: 4.h),
          _DayGrid(cells: _buildCells(), digits: _digits),
        ],
      ),
    );
  }
}

/// The Arabic <-> Bangla indicator inside the selected Arabic tab: thumb on
/// "ع" while the calendar is in Arabic (the default), on "বা" while it is in
/// Bangla. It only shows the state; the tab it sits in is the tap target.
class _ArabicFormatSwitch extends StatelessWidget {
  const _ArabicFormatSwitch({required this.inBangla});

  final bool inBangla;

  static const _duration = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    final width = 38.w;
    final height = 20.h;
    return Semantics(
      toggled: inBangla,
      label: AppText.of(context).calendarArabicInBangla,
      child: Container(
        key: const ValueKey('arabic-format-switch'),
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: context.surfaceColor(const Color(0xFFEEF3D6)),
          borderRadius: BorderRadius.circular(height),
          border: Border.all(color: AppColor.primary),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: _duration,
              curve: Curves.easeOut,
              alignment: inBangla
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: .5,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColor.primary,
                    borderRadius: BorderRadius.circular(height),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                _end('ع', selected: !inBangla),
                _end('বা', selected: inBangla),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _end(String text, {required bool selected}) => Expanded(
    child: Center(
      child: AnimatedDefaultTextStyle(
        duration: _duration,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : AppColor.primary,
          height: 1.1,
        ),
        child: Text(text),
      ),
    ),
  );
}

class _TabRow extends StatelessWidget {
  const _TabRow({
    required this.tab,
    required this.banglaLabel,
    required this.arabicLabel,
    required this.englishLabel,
    required this.arabicInBangla,
    required this.onChanged,
  });

  final _CalTab tab;
  final String banglaLabel;
  final String arabicLabel;
  final String englishLabel;

  /// Which form the Arabic tab is showing, for its built-in indicator.
  final bool arabicInBangla;

  /// Called with the tab tapped, including a tap on the tab already selected
  /// (the Arabic tab uses that to flip its display language).
  final ValueChanged<_CalTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final entries = {
      _CalTab.bangla: banglaLabel,
      _CalTab.arabic: arabicLabel,
      _CalTab.english: englishLabel,
    };
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final entry in entries.entries)
          Flexible(
            child: InkWell(
              onTap: () => onChanged(entry.key),
              borderRadius: BorderRadius.circular(20.r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: entry.key == tab
                      ? context.surfaceColor(context.appPalette.tint)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                // Shrinks rather than overflows on a narrow screen or with
                // large system text.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        entry.value,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: entry.key == tab
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: entry.key == tab
                              ? context.inkColor(const Color(0xFF3A4A1F))
                              : context.inkColor(const Color(0xFF8A927A)),
                        ),
                      ),
                      // The toggle lives in the Arabic tab itself.
                      if (entry.key == _CalTab.arabic &&
                          tab == _CalTab.arabic) ...[
                        SizedBox(width: 8.w),
                        _ArabicFormatSwitch(inBangla: arabicInBangla),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MonthYearRow extends StatelessWidget {
  const _MonthYearRow({
    required this.yearLabel,
    required this.monthName,
    required this.textDirection,
    required this.onTapYear,
    required this.onTapMonth,
  });

  final String yearLabel;
  final String monthName;
  final TextDirection textDirection;
  final VoidCallback onTapYear;
  final VoidCallback onTapMonth;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: context.lineColor(context.appPalette.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _Segment(label: yearLabel, onTap: onTapYear),
          _Segment(
            label: monthName,
            textDirection: textDirection,
            onTap: onTapMonth,
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.onTap,
    this.textDirection = TextDirection.ltr,
  });

  final String label;
  final VoidCallback onTap;
  final TextDirection textDirection;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              textDirection: textDirection,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: context.inkColor(const Color(0xFF2A331C)),
              ),
            ),
            SizedBox(width: 6.w),
            HomeCircleButton(
              icon: Icons.keyboard_arrow_down_rounded,
              onPressed: onTap,
              size: 20.r,
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader({required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final label in labels)
          Expanded(
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: context.inkColor(const Color(0xFF6B7458)),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DayGrid extends StatelessWidget {
  const _DayGrid({required this.cells, required this.digits});

  final List<_CalCell> cells;
  final List<String>? digits;

  @override
  Widget build(BuildContext context) {
    if (cells.isEmpty) return const SizedBox.shrink();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cells.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
      ),
      itemBuilder: (context, index) {
        final cell = cells[index];
        return Center(
          child: Container(
            width: 28.r,
            height: 28.r,
            alignment: Alignment.center,
            decoration: cell.isToday
                ? BoxDecoration(
                    color: context.surfaceColor(context.appPalette.tint),
                    shape: BoxShape.circle,
                  )
                : null,
            child: Text(
              _localizeDigits(cell.day, digits),
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: cell.isToday ? FontWeight.w700 : FontWeight.w400,
                color: cell.inMonth
                    ? context.inkColor(const Color(0xFF2A331C))
                    : context.inkColor(const Color(0xFFC3C9B4)),
              ),
            ),
          ),
        );
      },
    );
  }
}
