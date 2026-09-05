import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/dua/data/dua_catalog.dart';

/// The pastel-green "Duas for help" card shown on the dashboard's Featured
/// Dua row and on the full Featured Dua list (design `img_1.png` /
/// `img_3.png`).
class DuaFeaturedCard extends StatelessWidget {
  const DuaFeaturedCard({super.key, required this.featured, this.onExplore});

  final DuaFeatured featured;

  /// Called when the "Explore" pill is tapped — opens the group's detail
  /// screen ([DuaGroupScreen], design `img_4.png`).
  final VoidCallback? onExplore;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 14.h),
      decoration: BoxDecoration(
        color: const Color(0xFFDCE8C4),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFC7D6A6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34.r,
                height: 34.r,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(9.r),
                  border: Border.all(color: const Color(0xFFC7D6A6)),
                ),
                child: Icon(
                  Icons.badge_outlined,
                  color: const Color(0xFF6B7A4A),
                  size: 18.sp,
                ),
              ),
              InkWell(
                onTap: onExplore,
                borderRadius: BorderRadius.circular(16.r),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: const Color(0xFF3C4A28)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        appText.duaExplore,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(Icons.north_east_rounded, size: 13.sp),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                featured.title,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF3C4A28),
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                '${appText.duaTotalDuaLabel} : ${featured.totalDua}',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: const Color(0xFF5D6B44),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
