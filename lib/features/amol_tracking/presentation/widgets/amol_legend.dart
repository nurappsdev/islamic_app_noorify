import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';

import 'amol_chart_painters.dart';

class AmolLegend extends StatelessWidget {
  const AmolLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Row(
      children: [
        _AmolLegendDot(
          color: AmolLineChartPainter.lineColor,
          label: appText.myPosition,
        ),
        SizedBox(width: 18.w),
        _AmolLegendDot(
          color: AmolLineChartPainter.competitorLineColor,
          label: appText.myNearestOrCompetitor,
        ),
      ],
    );
  }
}

class _AmolLegendDot extends StatelessWidget {
  const _AmolLegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9.r,
          height: 9.r,
          decoration: BoxDecoration(
            color: context.surfaceColor(color),
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 6.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: context.inkColor(Colors.black87),
          ),
        ),
      ],
    );
  }
}
