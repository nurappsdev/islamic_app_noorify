import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';

import 'amol_dashboard_period.dart';

/// Daily's existing two-part "Todays – average todays days." caption;
/// weekly/monthly have no analogous clause, so they show just the
/// corrected heading ("This Week's"/"This Month's Average") in the same
/// bold-italic style as daily's "Todays".
class AmolAverageCaption extends StatelessWidget {
  const AmolAverageCaption({super.key, required this.period});

  final AmolPeriod period;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return RichText(
      text: period == AmolPeriod.daily
          ? TextSpan(
              children: [
                TextSpan(
                  text: appText.todays,
                  style: TextStyle(
                    color: context.inkColor(Colors.black),
                    fontSize: 15.sp,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: ' ${appText.averageTodaysDays}',
                  style: TextStyle(
                    color: context.inkColor(Colors.black87),
                    fontSize: 13.sp,
                  ),
                ),
              ],
            )
          : TextSpan(
              text: period == AmolPeriod.weekly
                  ? appText.thisWeeksAverage
                  : appText.thisMonthsAverage,
              style: TextStyle(
                color: context.inkColor(Colors.black),
                fontSize: 15.sp,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}
