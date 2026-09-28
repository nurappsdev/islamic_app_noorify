import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';

import '../../quran_text.dart';

/// Available period filters matching Hadith dashboard structure.
enum QuranDashboardPeriod { daily, weekly, monthly }

typedef QuranHistoryPeriod = QuranDashboardPeriod;

/// Period filter dropdown button matching the Hadith dashboard mechanism:
/// Daily / Weekly / Monthly, and inside Monthly the 12 calendar months.
/// Shows the picked month's name when one is selected.
class QuranPeriodDropdown extends StatelessWidget {
  const QuranPeriodDropdown({
    super.key,
    required this.period,
    required this.month,
    required this.labelFor,
    required this.onChanged,
  });

  final QuranHistoryPeriod period;

  /// The picked month (first day), or null for rolling periods.
  final DateTime? month;
  final String Function(QuranHistoryPeriod) labelFor;
  final void Function(QuranHistoryPeriod period, {DateTime? month}) onChanged;

  @override
  Widget build(BuildContext context) {
    final picked = month;
    return PopupMenuButton<void>(
      color: Colors.white,
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
      itemBuilder: (_) => [
        PopupMenuItem<void>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: _QuranPeriodMenu(
            period: period,
            month: month,
            labelFor: labelFor,
            onChanged: onChanged,
          ),
        ),
      ],
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: context.surfaceColor(const Color(0xFFDEE99D)),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              picked == null
                  ? labelFor(period)
                  : QuranText.of(context).monthName(picked.month),
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: context.inkColor(const Color(0xFF2C3320)),
              ),
            ),
            SizedBox(width: 6.w),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20.sp,
              color: context.inkColor(const Color(0xFF2C3320)),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuranPeriodMenu extends StatefulWidget {
  const _QuranPeriodMenu({
    required this.period,
    required this.month,
    required this.labelFor,
    required this.onChanged,
  });

  final QuranHistoryPeriod period;
  final DateTime? month;
  final String Function(QuranHistoryPeriod) labelFor;
  final void Function(QuranHistoryPeriod period, {DateTime? month}) onChanged;

  @override
  State<_QuranPeriodMenu> createState() => _QuranPeriodMenuState();
}

class _QuranPeriodMenuState extends State<_QuranPeriodMenu> {
  late QuranHistoryPeriod _period = widget.period;
  late DateTime? _month = widget.month;
  late bool _monthsOpen = widget.period == QuranHistoryPeriod.monthly;

  void _pick(QuranHistoryPeriod period, {DateTime? month, bool close = true}) {
    setState(() {
      _period = period;
      _month = month;
    });
    widget.onChanged(period, month: month);
    if (close) Navigator.of(context).pop();
  }

  void _onMonthly() {
    final rollingMonthly =
        _period == QuranHistoryPeriod.monthly && _month == null;
    if (rollingMonthly) {
      setState(() => _monthsOpen = !_monthsOpen);
    } else {
      _pick(QuranHistoryPeriod.monthly, close: false);
      setState(() => _monthsOpen = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final t = QuranText.of(context);
    // A share of the screen rather than a fixed width.
    return SizedBox(
      width: MediaQuery.sizeOf(context).width * .6,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _QuranMenuRow(
            label: widget.labelFor(QuranHistoryPeriod.daily),
            active: _period == QuranHistoryPeriod.daily,
            onTap: () => _pick(QuranHistoryPeriod.daily),
          ),
          _QuranMenuRow(
            label: widget.labelFor(QuranHistoryPeriod.weekly),
            active: _period == QuranHistoryPeriod.weekly,
            onTap: () => _pick(QuranHistoryPeriod.weekly),
          ),
          _QuranMenuRow(
            label: widget.labelFor(QuranHistoryPeriod.monthly),
            active: _period == QuranHistoryPeriod.monthly,
            trailing: Icon(
              _monthsOpen
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 20.sp,
              color: context.inkColor(const Color(0xFF3E4A2A)),
            ),
            onTap: _onMonthly,
          ),
          if (_monthsOpen)
            Padding(
              padding: EdgeInsets.fromLTRB(12.w, 4.h, 12.w, 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: Text(
                      t.n(now.year),
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: context.inkColor(const Color(0xFF6A7350)),
                      ),
                    ),
                  ),
                  // Four equal columns sharing the menu's width.
                  GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8.h,
                    crossAxisSpacing: 8.w,
                    childAspectRatio: 1.8,
                    children: [
                      for (var m = 1; m <= 12; m++)
                        _QuranMonthChip(
                          name: t.monthShort(m),
                          enabled: m <= now.month,
                          selected:
                              _month?.year == now.year && _month?.month == m,
                          onTap: () => _pick(
                            QuranHistoryPeriod.monthly,
                            month: DateTime(now.year, m),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _QuranMenuRow extends StatelessWidget {
  const _QuranMenuRow({
    required this.label,
    required this.active,
    required this.onTap,
    this.trailing,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        color: active ? const Color(0xFFEDF3D6) : Colors.transparent,
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: context.inkColor(const Color(0xFF2C3320)),
                ),
              ),
            ),
            if (trailing != null)
              IconTheme.merge(
                data: const IconThemeData(opacity: 1),
                child: trailing!,
              ),
          ],
        ),
      ),
    );
  }
}

class _QuranMonthChip extends StatelessWidget {
  const _QuranMonthChip({
    required this.name,
    required this.enabled,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final bool enabled;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.surfaceColor(
            selected ? const Color(0xFF5D7858) : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: context.lineColor(
              selected ? const Color(0xFF5D7858) : const Color(0xFFC7D2A0),
            ),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            name,
            maxLines: 1,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: selected
                  ? Colors.white
                  : context.inkColor(
                      enabled
                          ? const Color(0xFF2C3320)
                          : const Color(0xFFB4B9A6),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
