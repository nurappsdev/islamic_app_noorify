import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/localized_text.dart';

// The pieces of a quiz question screen, shared by the normal quiz and the
// planned (scheduled) quiz so both look the same.

class QuizQuestionAppBar extends StatelessWidget {
  const QuizQuestionAppBar({
    super.key,
    required this.title,
    required this.onBack,
  });
  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 38.h,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: onBack,
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFDFDE68),
              foregroundColor: Color(0xFF303629),
            ),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 48.w),
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColor.primary, fontSize: 18.sp),
          ),
        ),
      ],
    ),
  );
}

class QuizTimerPill extends StatelessWidget {
  const QuizTimerPill({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 13.h),
    decoration: BoxDecoration(
      color: AppColor.primary,
      borderRadius: BorderRadius.circular(28.r),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.access_time_rounded, color: Colors.white, size: 22.sp),
        SizedBox(width: 10.w),
        // Shrinks with an ellipsis rather than overflow on a narrow screen.
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white, fontSize: 14.sp),
          ),
        ),
      ],
    ),
  );
}

class QuizQuestionProgress extends StatelessWidget {
  const QuizQuestionProgress({super.key, required this.value});

  /// Share of the questions reached, 0-1.
  final double value;

  @override
  Widget build(BuildContext context) {
    final progress = value.clamp(0.0, 1.0);
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        Container(
          height: 8.h,
          decoration: BoxDecoration(
            color: context.surfaceColor(Color(0xFFE9E9E9)),
            borderRadius: BorderRadius.circular(20.r),
          ),
        ),
        FractionallySizedBox(
          widthFactor: progress,
          child: Container(
            height: 8.h,
            decoration: BoxDecoration(
              color: AppColor.primary,
              borderRadius: BorderRadius.circular(20.r),
            ),
          ),
        ),
        Align(
          alignment: Alignment(progress * 2 - 1, 0),
          child: Container(
            width: 22.r,
            height: 22.r,
            decoration: const BoxDecoration(
              color: AppColor.primary,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

class QuizAnswerTile extends StatelessWidget {
  const QuizAnswerTile({
    super.key,
    required this.label,
    required this.answer,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String answer;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: context.surfaceColor(Color(0xFFF2F6E7)),
    borderRadius: BorderRadius.circular(15.r),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15.r),
      child: Container(
        // Grows for a long answer instead of clipping it.
        constraints: BoxConstraints(minHeight: 48.h),
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        child: Row(
          children: [
            Container(
              height: 29.r,
              width: 29.r,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: context.lineColor(Color(0xFFDDE8B5))),
                shape: BoxShape.circle,
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: context.inkColor(Color(0xFF596254)),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                answer,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: const Color(0xFF899580),
                ),
              ),
            ),
            if (selected)
              Container(
                height: 24.r,
                width: 24.r,
                decoration: BoxDecoration(
                  color: AppColor.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.lineColor(Colors.white),
                    width: 2,
                  ),
                ),
                child: const SizedBox(),
              ),
          ],
        ),
      ),
    ),
  );
}

class QuizTimingProgress extends StatelessWidget {
  const QuizTimingProgress({super.key, required this.value});

  /// Share of the time limit used, 0-1.
  final double value;

  @override
  Widget build(BuildContext context) {
    final progress = value.clamp(0.0, 1.0);
    return Container(
      height: 55.h,
      decoration: BoxDecoration(
        color: context.surfaceColor(Color(0xFFDDE8B5)),
        borderRadius: BorderRadius.circular(30.r),
      ),
      child: Align(
        alignment: Alignment(progress * 2 - 1, 0),
        child: Container(
          width: 58.r,
          height: 58.r,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.surfaceColor(Color(0xFFDDE8B5)),
            shape: BoxShape.circle,
            border: Border.all(
              color: context.lineColor(Colors.white.withValues(alpha: .7)),
            ),
          ),
          child: Text(
            context.localizedDigits('${(progress * 100).round()} %'),
            style: TextStyle(
              color: context.inkColor(Color(0xFF5D876A)),
              fontSize: 13.sp,
            ),
          ),
        ),
      ),
    );
  }
}
