import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';

/// Lets the user jump the monthly tab straight to one of the last 12
/// calendar months (e.g. "August 2026"), instead of stepping 30 days at a
/// time via [AmolDateNavigator]'s arrows.
class AmolMonthDropdown extends StatelessWidget {
  const AmolMonthDropdown({
    super.key,
    required this.selectedMonth,
    required this.months,
    required this.appText,
    required this.onChanged,
  });

  final DateTime selectedMonth;
  final List<DateTime> months;
  final AppText appText;
  final ValueChanged<DateTime> onChanged;

  String _label(BuildContext context, DateTime month) => context
      .localizedDigits('${appText.monthNames[month.month - 1]} ${month.year}');

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 2.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: context.lineColor(Color(0xFFDCE9B8))),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<DateTime>(
          // Falls back to a hint (rather than asserting) when the current
          // selection isn't one of the last 12 months, e.g. after stepping
          // further back with the date-navigator arrows.
          value: months.contains(selectedMonth) ? selectedMonth : null,
          hint: Text(
            _label(context, selectedMonth),
            style: TextStyle(
              fontSize: 13.sp,
              color: context.inkColor(Colors.black),
            ),
          ),
          isDense: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: context.inkColor(Color(0xFF7E8C61)),
            size: 18.sp,
          ),
          borderRadius: BorderRadius.circular(16.r),
          dropdownColor: context.surfaceColor(Colors.white),
          style: TextStyle(
            fontSize: 13.sp,
            color: context.inkColor(Colors.black),
          ),
          items: [
            for (final month in months)
              DropdownMenuItem(
                value: month,
                child: Text(_label(context, month)),
              ),
          ],
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ),
    );
  }
}
