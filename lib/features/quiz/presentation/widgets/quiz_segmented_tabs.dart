import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';

/// The quiz screens' row of equal-width tabs, the selected one filled.
class QuizSegmentedTabs extends StatelessWidget {
  const QuizSegmentedTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    this.fontSize,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  /// Defaults to 16.sp.
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44.h,
      child: Row(
        children: [
          for (var index = 0; index < labels.length; index++)
            Expanded(
              child: InkWell(
                onTap: () => onChanged(index),
                borderRadius: BorderRadius.circular(13.r),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.surfaceColor(
                      selectedIndex == index
                          ? const Color(0xFFDDE8BA)
                          : Colors.transparent,
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: context.lineColor(
                          selectedIndex == index
                              ? Colors.transparent
                              : const Color(0xFFDDE8C1),
                        ),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(13.r),
                  ),
                  child: Text(
                    labels[index],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: fontSize ?? 16.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
