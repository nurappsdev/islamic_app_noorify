import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';

/// The "Dua - N" row tile shown in a Dua group's "All dua" list (design
/// `img_4.png` / `img_5.png`).
class DuaItemTile extends StatelessWidget {
  const DuaItemTile({super.key, required this.name, this.onTap});

  final String name;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: context.surfaceColor(Colors.white),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: context.lineColor(Color(0xFFE3E7D3))),
        ),
        child: Row(
          children: [
            Container(
              width: 8.r,
              height: 8.r,
              decoration: const BoxDecoration(
                color: Color(0xFF9BA85B),
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: context.inkColor(Color(0xFF2C3320)),
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              color: const Color(0xFF9BA85B),
              size: 18.sp,
            ),
          ],
        ),
      ),
    );
  }
}
