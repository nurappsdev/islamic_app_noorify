import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/features/dua/data/dua_catalog.dart';

/// The bordered icon-and-label tile for a [DuaCategory], shown on both the
/// dashboard's category preview grid and the full "All Category" grid
/// (design `img_1.png` / `img_2.png`).
class DuaCategoryTile extends StatelessWidget {
  const DuaCategoryTile({super.key, required this.category});

  final DuaCategory category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      decoration: BoxDecoration(
        color: context.surfaceColor(Colors.white),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: context.lineColor(Color(0xFFE3E7D3))),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(category.icon, color: const Color(0xFF9BA85B), size: 26.sp),
          SizedBox(height: 8.h),
          Text(
            category.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.sp,
              color: context.inkColor(Color(0xFF5D6B44)),
            ),
          ),
        ],
      ),
    );
  }
}
