import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hijri/hijri_calendar.dart';

import 'package:islami_app_noorify/core/theme/app_palette.dart';
import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/home/domain/calendar/bangla_date.dart';
import 'package:islami_app_noorify/features/home/presentation/screens/home_screen.dart';

enum _CalTab { bangla, arabic, english }

const _banglaDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
const _arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

/// Western digits in [value] mapped through [digits] (Bangla/Arabic-Indic);
/// `null` leaves western digits untouched.
String _localizeDigits(int value, List<String>? digits) {
  if (digits == null) return '$value';
  return '$value'.split('').map((c) => digits[int.parse(c)]).join();
}

const _monthNamesEn = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

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

/// Common Bangla transliteration of the Hijri month names, for the Hijri
/// line shown under the Bangla tab.
const _hijriMonthNamesBn = [
  'মুহাররম',
  'সফর',
  'রবিউল আউয়াল',
  'রবিউস সানি',
  'জমাদিউল আউয়াল',
  'জমাদিউস সানি',
  'রজব',
  'শাবান',
  'রমজান',
  'শাওয়াল',
  'জিলকদ',
  'জিলহজ',
];

const _hijriWeekdayShortAr = ['أحد', 'اثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة', 'سبت'];

// Index 0 = Sunday .. 6 = Saturday, to match DateTime.weekday % 7. The 7-day
// week is shared by every calendar system here, so one weekday index drives
// all three name sets.
const _weekdayFullEn = [
  'Sunday',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
];

const _weekdayFullBn = [
  'রবিবার',
  'সোমবার',
  'মঙ্গলবার',
  'বুধবার',
  'বৃহস্পতিবার',
  'শুক্রবার',
  'শনিবার',
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
  const _CalCell({required this.day, required this.inMonth, required this.isToday});

  final int day;
  final bool inMonth;
  final bool isToday;
}

/// The Bangla / Arabic / English calendar card shown on the home screen,
/// right after the Qiblah compass card. Each tab is its own native calendar
/// system, not a relabeled Gregorian grid:
/// - Bangla: the Bengali solar calendar, plus today's Hijri date written in
///   Bangla script underneath.
/// - Arabic: the Hijri lunar calendar, in Arabic script and digits.
/// - English: the plain Gregorian calendar.
class HomeCalendarCard extends StatefulWidget {
  const HomeCalendarCard({super.key});

  @override
  State<HomeCalendarCard> createState() => _HomeCalendarCardState();
}

class _HomeCalendarCardState extends State<HomeCalendarCard> {
  _CalTab _tab = _CalTab.english;

  late int _enYear;
  late int _enMonth;
  late int _bnYear;
  late int _bnMonth;
  late int _hYear;
  late int _hMonth;

  late final DateTime _todayEn;
  late final BanglaDate _todayBn;
  late final int _todayHYear;
  late final int _todayHMonth;
  late final int _todayHDay;

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

    final hc = HijriCalendar.fromDate(now);
    _todayHYear = hc.hYear;
    _todayHMonth = hc.hMonth;
    _todayHDay = hc.hDay;
    _hYear = hc.hYear;
    _hMonth = hc.hMonth;
  }

  List<String>? get _digits => switch (_tab) {
    _CalTab.bangla => _banglaDigits,
    _CalTab.arabic => _arabicDigits,
    _CalTab.english => null,
  };

  TextDirection get _textDirection =>
      _tab == _CalTab.arabic ? TextDirection.rtl : TextDirection.ltr;

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
    _CalTab.english => _monthNamesEn,
    _CalTab.bangla => BanglaDate.monthNames,
    _CalTab.arabic => _hijriMonthNamesAr,
  };

  List<String> get _weekdayShort => switch (_tab) {
    _CalTab.english => _weekdayShortEn,
    _CalTab.bangla => BanglaDate.weekdayShortNames,
    _CalTab.arabic => _hijriWeekdayShortAr,
  };

  /// Today's date written in this tab's own calendar system and script.
  String _primaryTodayLine() {
    final wIdx = _todayEn.weekday % 7; // Sun=0..Sat=6, shared 7-day week.
    switch (_tab) {
      case _CalTab.english:
        return '${_weekdayFullEn[wIdx]}, ${_todayEn.day} '
            '${_monthNamesEn[_todayEn.month - 1]} ${_todayEn.year}';
      case _CalTab.bangla:
        final d = _localizeDigits(_todayBn.day, _banglaDigits);
        final y = _localizeDigits(_todayBn.year, _banglaDigits);
        return '${_weekdayFullBn[wIdx]}, $d '
            '${BanglaDate.monthNames[_todayBn.month - 1]} $y';
      case _CalTab.arabic:
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
    return 'হিজরি: $d ${_hijriMonthNamesBn[_todayHMonth - 1]} $y';
  }

  String get _todayLabelEnglish {
    final wIdx = _todayEn.weekday % 7;
    return '${_weekdayFullEn[wIdx]}, ${_todayEn.day} '
        '${_monthNamesEn[_todayEn.month - 1]} ${_todayEn.year}';
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
            firstWeekday: _hijri.hijriToGregorian(_hYear, _hMonth, 1).weekday,
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
            title: Text(names[index], textDirection: _textDirection),
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

  Future<void> _pickYear() async {
    final appText = AppText.of(context);
    final controller = TextEditingController(text: '$_year');
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(appText.zikrCancel),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(int.tryParse(controller.text)),
            child: Text(appText.confirm),
          ),
        ],
      ),
    );
    if (result != null) _setYear(result);
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final showBanglaHijriLine = _tab == _CalTab.bangla;
    final showEnglishGloss = _tab == _CalTab.arabic;
    return HomeCard(
      padding: EdgeInsets.all(12.w),
      child: Column(
        children: [
          _TabRow(
            tab: _tab,
            banglaLabel: appText.bangla,
            arabicLabel: appText.quranArabicLabel,
            englishLabel: appText.english,
            onChanged: (t) => setState(() => _tab = t),
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
          if (showEnglishGloss) ...[
            SizedBox(height: 2.h),
            Text(
              _todayLabelEnglish,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.sp,
                color: context.inkColor(const Color(0xFF9AA187)),
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

class _TabRow extends StatelessWidget {
  const _TabRow({
    required this.tab,
    required this.banglaLabel,
    required this.arabicLabel,
    required this.englishLabel,
    required this.onChanged,
  });

  final _CalTab tab;
  final String banglaLabel;
  final String arabicLabel;
  final String englishLabel;
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
          InkWell(
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
              child: Text(
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
          _Segment(label: monthName, textDirection: textDirection, onTap: onTapMonth),
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
