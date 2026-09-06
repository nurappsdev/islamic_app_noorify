import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/core/constants/route_names.dart';

/// Navigation bar shown on the Dua dashboard (design `img_1.png`).
///
/// Only "Home" is wired today. The bookmark and category shortcuts match the
/// design but don't have dedicated screens yet, so they're rendered
/// non-interactive until a Saved Dua / quick-category screen exists.
class DuaBottomNav extends StatelessWidget {
  const DuaBottomNav({super.key, this.selectedIndex = 0});

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
            _DuaNavItem(
              icon: Icons.home_outlined,
              label: appText.home,
              selected: selectedIndex == 0,
              onTap: () =>
                  Navigator.of(context).pushNamed(RouteNames.duaDashboard),
            ),
            _DuaNavItem(
              icon: Icons.bookmark_border_rounded,
              label: 'Saved',
              selected: selectedIndex == 1,
              onTap: () => Navigator.of(context).pushNamed(RouteNames.duaSaved),
            ),
            const _DuaNavItem(icon: Icons.fact_check_outlined),
          ],
        ),
      ),
    );
  }
}

class _DuaNavItem extends StatelessWidget {
  const _DuaNavItem({
    required this.icon,
    this.label,
    this.selected = false,
    this.onTap,
  });

  final IconData icon;
  final String? label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (!selected) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 7.h),
          child: Icon(icon, color: Colors.white, size: 18.sp),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
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
    );
  }
}
