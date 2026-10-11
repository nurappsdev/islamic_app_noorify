import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';

import 'amol_chart_painters.dart';
import 'amol_dashboard_utils.dart';

/// Shown when a category column is tapped: the exact myScore/competitorScore
/// values behind that point on the chart.
class AmolScoreTooltip extends StatelessWidget {
  const AmolScoreTooltip({
    super.key,
    required this.title,
    required this.myLabel,
    required this.myScore,
    required this.competitorLabel,
    required this.competitorScore,
  });

  final String title;
  final String myLabel;
  final double myScore;
  final String competitorLabel;
  final double? competitorScore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      constraints: BoxConstraints(minWidth: 112.w),
      decoration: BoxDecoration(
        color: context.surfaceColor(Colors.white),
        borderRadius: BorderRadius.circular(10.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      // The tooltip sits in a Positioned with no width, so its rows (which
      // use Expanded) need a finite width: IntrinsicWidth provides one.
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
                color: context.inkColor(Colors.black87),
              ),
            ),
            SizedBox(height: 4.h),
            _AmolTooltipRow(
              color: AmolLineChartPainter.lineColor,
              label: myLabel,
              value: context.localizedDigits(formatAmolScoreValue(myScore)),
            ),
            SizedBox(height: 2.h),
            _AmolTooltipRow(
              color: AmolLineChartPainter.competitorLineColor,
              label: competitorLabel,
              value: competitorScore == null
                  ? '—'
                  : context.localizedDigits(
                      formatAmolScoreValue(competitorScore!),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmolTooltipRow extends StatelessWidget {
  const _AmolTooltipRow({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 7.r,
          height: 7.r,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 5.w),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.sp,
              color: context.inkColor(Colors.black87),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w700,
            color: context.inkColor(Colors.black),
          ),
        ),
      ],
    );
  }
}
