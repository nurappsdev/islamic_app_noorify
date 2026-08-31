import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';

/// Navigation bar dedicated to the Hadith flow.
///
/// The Hadith Library is this flow's Home destination at index 0; the Hadith
/// Planner sits at index 1 and is shown with its "Planner" label.
class HadithBottomNav extends StatelessWidget {
  const HadithBottomNav({super.key, this.selectedIndex = 0});

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
            _HadithNavItem(
              icon: Icons.home_outlined,
              label: appText.home,
              selected: selectedIndex == 0,
              onPressed: selectedIndex == 0
                  ? null
                  : () => Navigator.of(
                      context,
                    ).pushReplacementNamed(RouteNames.hadithLibrary),
            ),
            _HadithNavItem(
              icon: Icons.fact_check_outlined,
              label: appText.planner,
              selected: selectedIndex == 1,
              onPressed: selectedIndex == 1
                  ? null
                  : () => Navigator.of(
                      context,
                    ).pushReplacementNamed(RouteNames.hadithPlanner),
            ),
            const _HadithNavItem(icon: Icons.bookmark_border_rounded),
            const _HadithNavItem(icon: Icons.grid_view_rounded),
          ],
        ),
      ),
    );
  }
}

class _HadithNavItem extends StatelessWidget {
  const _HadithNavItem({
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
