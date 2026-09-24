import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/theme/app_palette.dart';

/// Wraps [child] with the app-wide shimmer sweep used for loading skeletons
/// (same colors as [QuranShimmer], kept local to this feature).
class HomeShimmer extends StatelessWidget {
  const HomeShimmer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: context.appPalette.shimmerBase,
      highlightColor: context.appPalette.shimmerHighlight,
      child: child,
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({this.width, this.height = 12, this.radius = 6});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.surfaceColor(Colors.white),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Skeleton for [AmalTrackerCard] while `GET /home/dashboard` is loading:
/// one card-shaped slide matching the real carousel's height.
class AmalTrackerCardShimmer extends StatelessWidget {
  const AmalTrackerCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return HomeShimmer(
      child: Container(
        height: 100.h,
        padding: EdgeInsets.fromLTRB(9.w, 9.h, 9.w, 9.h),
        decoration: BoxDecoration(
          color: context.surfaceColor(Colors.white),
          borderRadius: BorderRadius.circular(22.r),
        ),
        child: Row(
          children: [
            _ShimmerBox(width: 52.r, height: 52.r, radius: 12.r),
            SizedBox(width: 7.w),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ShimmerBox(width: 120.w, height: 12.h, radius: 4.r),
                  SizedBox(height: 8.h),
                  _ShimmerBox(width: 80.w, height: 10.h, radius: 4.r),
                ],
              ),
            ),
            SizedBox(width: 4.w),
            _ShimmerBox(width: 84.r, height: 84.r, radius: 42.r),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for [HomeProgressSection] while `GET /home/dashboard` is
/// loading: the 2x3 pillar grid plus the full-width "Nafl & more" card.
class HomeProgressSectionShimmer extends StatelessWidget {
  const HomeProgressSectionShimmer({super.key, this.gridItemCount = 6});

  final int gridItemCount;

  @override
  Widget build(BuildContext context) {
    return HomeShimmer(
      child: Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: gridItemCount,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 90.h,
              crossAxisSpacing: 11.w,
              mainAxisSpacing: 8.h,
            ),
            itemBuilder: (context, index) => Container(
              padding: EdgeInsets.symmetric(vertical: 9.h),
              decoration: BoxDecoration(
                color: context.surfaceColor(Colors.white),
                borderRadius: BorderRadius.circular(11.r),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ShimmerBox(width: 70.w, height: 12.h, radius: 4.r),
                  SizedBox(height: 7.h),
                  _ShimmerBox(width: 64.w, height: 4.h, radius: 4.r),
                  SizedBox(height: 6.h),
                  _ShimmerBox(width: 40.w, height: 12.h, radius: 4.r),
                ],
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 13.h),
            decoration: BoxDecoration(
              color: context.surfaceColor(Colors.white),
              borderRadius: BorderRadius.circular(11.r),
            ),
            child: Column(
              children: [
                _ShimmerBox(width: 100.w, height: 12.h, radius: 4.r),
                SizedBox(height: 6.h),
                _ShimmerBox(width: 64.w, height: 4.h, radius: 4.r),
                SizedBox(height: 7.h),
                _ShimmerBox(width: 40.w, height: 12.h, radius: 4.r),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
