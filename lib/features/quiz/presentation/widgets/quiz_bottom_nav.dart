import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/quiz/presentation/screens/quiz_shell.dart';

/// Navigation bar dedicated to the Quiz & Learn flow.
///
/// Quiz Categories is the Quiz flow's Home destination, at index 0. The bar
/// lives once in [QuizShell]; a page pushed over the section can show its own
/// copy, whose taps return to the section.
class QuizBottomNav extends StatelessWidget {
  const QuizBottomNav({super.key, this.selectedIndex = 0, this.onSelected});

  /// Home, Learn, Planner, Dashboard.
  static const tabCount = 4;

  static const _barColor = Color(0xFFA1AD59);

  final int selectedIndex;

  /// Called with the tapped tab; without it the tap goes through
  /// [QuizShell.switchTo].
  final ValueChanged<int>? onSelected;

  static List<({IconData icon, IconData? selectedIcon, String label})> _items(
    AppText appText,
  ) => [
    (
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: appText.home,
    ),
    (
      icon: Icons.emoji_objects_outlined,
      selectedIcon: null,
      label: appText.learn,
    ),
    (
      icon: Icons.assignment_turned_in_outlined,
      selectedIcon: null,
      label: appText.planner,
    ),
    (
      icon: Icons.grid_view_outlined,
      selectedIcon: null,
      label: appText.dashboard,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 9.h),
      child: Container(
        height: 62.h,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          color: _barColor,
          borderRadius: BorderRadius.circular(32.r),
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
            for (final (index, item) in _items(appText).indexed)
              _QuizNavItem(
                icon: item.icon,
                selectedIcon: item.selectedIcon,
                label: item.label,
                selected: selectedIndex == index,
                onPressed: selectedIndex == index
                    ? null
                    : () => onSelected != null
                          ? onSelected!(index)
                          : QuizShell.switchTo(context, index),
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
    this.selectedIcon,
    this.label,
    this.selected = false,
    this.onPressed,
  });

  final IconData icon;
  final IconData? selectedIcon;
  final String? label;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    if (!selected) {
      return IconButton(
        tooltip: label,
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 22.sp),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
          decoration: BoxDecoration(
            color: const Color(0xFF5B8267),
            borderRadius: BorderRadius.circular(24.r),
          ),
          child: Row(
            children: [
              Icon(selectedIcon ?? icon, color: Colors.white, size: 20.sp),
              SizedBox(width: 6.w),
              Text(
                label ?? '',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
