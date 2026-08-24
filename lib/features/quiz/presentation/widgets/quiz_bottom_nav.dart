import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';

/// Navigation bar dedicated to the Quiz & Learn flow.
///
/// Quiz Categories is the Quiz flow's Home destination, at index 0.
class QuizBottomNav extends StatelessWidget {
  const QuizBottomNav({super.key, this.selectedIndex = 0});

  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 9.h),
      child: Container(
        height: 50.h,
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        decoration: BoxDecoration(
          color: AppColor.primary,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .08),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _QuizNavItem(
              icon: Icons.home_outlined,
              label: appText.home,
              selected: selectedIndex == 0,
              onPressed: selectedIndex == 0
                  ? null
                  : () => Navigator.of(
                      context,
                    ).pushReplacementNamed(RouteNames.winQuiz),
            ),
            _QuizNavItem(
              icon: Icons.lightbulb_outline_rounded,
              label: appText.learn,
              selected: selectedIndex == 1,
              onPressed: selectedIndex == 1
                  ? null
                  : () => Navigator.of(
                      context,
                    ).pushReplacementNamed(RouteNames.learning),
            ),
            _QuizNavItem(
              icon: Icons.fact_check_outlined,
              label: appText.planner,
              selected: selectedIndex == 2,
              onPressed: selectedIndex == 2
                  ? null
                  : () => Navigator.of(
                      context,
                    ).pushReplacementNamed(RouteNames.planner),
            ),
            _QuizNavItem(
              icon: Icons.grid_view_rounded,
              label: appText.dashboard,
              selected: selectedIndex == 3,
              onPressed: selectedIndex == 3
                  ? null
                  : () => Navigator.of(
                      context,
                    ).pushReplacementNamed(RouteNames.quizDashboard),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizNavItem extends StatelessWidget {
  const _QuizNavItem({
    required this.icon,
    this.label,
    this.selected = false,
    this.onPressed,
  });

  final IconData icon;
  final String? label;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    if (!selected) {
      return IconButton(
        tooltip: label,
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 18.sp),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 7.h),
          decoration: BoxDecoration(
            color: const Color(0xFF738A69),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 16.sp),
              SizedBox(width: 4.w),
              Text(
                label ?? '',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
