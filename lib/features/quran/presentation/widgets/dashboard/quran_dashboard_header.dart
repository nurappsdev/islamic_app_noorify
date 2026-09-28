import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';

/// Top bar header for the Quran Dashboard with back button and title.
class QuranDashboardHeader extends StatelessWidget {
  const QuranDashboardHeader({
    super.key,
    required this.title,
    this.onBack,
  });

  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20.r),
                onTap: () {
                  if (onBack != null) {
                    onBack!();
                  } else {
                    Navigator.maybePop(context);
                  }
                },
                child: Container(
                  width: 38.r,
                  height: 38.r,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDEE99D),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.chevron_left_rounded,
                    size: 24,
                    color: Color(0xFF282828),
                  ),
                ),
              ),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: context.inkColor(const Color(0xFF677647)),
              fontSize: 21.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
