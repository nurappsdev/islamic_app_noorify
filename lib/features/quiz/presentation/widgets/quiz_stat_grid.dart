import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/localized_text.dart';

/// A labelled figure, shown as the server sent it.
typedef QuizStat = (String label, String value);

/// [stats] in rows of three tiles.
class QuizStatGrid extends StatelessWidget {
  const QuizStatGrid({super.key, required this.stats});

  final List<QuizStat> stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 16.w) / 3;
        return Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            for (final (label, value) in stats)
              SizedBox(
                width: width,
                child: QuizStatTile(
                  label: label,
                  value: context.localizedDigits(value),
                ),
              ),
          ],
        );
      },
    );
  }
}

class QuizStatTile extends StatelessWidget {
  const QuizStatTile({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 10.h),
    decoration: BoxDecoration(
      color: context.surfaceColor(Color(0xFFF2F6E7)),
      borderRadius: BorderRadius.circular(13.r),
    ),
    child: Column(
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: AppColor.primary, fontSize: 15.sp),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10.sp,
            color: context.inkColor(Color(0xFF56614F)),
          ),
        ),
      ],
    ),
  );
}
