import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

import 'package:islami_app_noorify/core/theme/app_palette.dart';
import 'package:islami_app_noorify/core/theme/theme_colors.dart';

/// Wraps [child] with the app-wide shimmer sweep used for loading skeletons
/// (same colors as [HomeShimmer]/[QuranShimmer], kept local to this
/// feature).
class QiblahShimmer extends StatelessWidget {
  const QiblahShimmer({super.key, required this.child});

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

/// Skeleton for [QiblahCompassScreen] while the first heading/permission
/// check is in flight: a chip-shaped bar, a circular block matching the
/// compass dial, and a calibration-hint sized line.
class QiblahCompassShimmer extends StatelessWidget {
  const QiblahCompassShimmer({super.key, required this.dialSize});

  final double dialSize;

  @override
  Widget build(BuildContext context) {
    return QiblahShimmer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 150.w,
            height: 34.h,
            decoration: BoxDecoration(
              color: context.surfaceColor(Colors.white),
              borderRadius: BorderRadius.circular(20.r),
            ),
          ),
          SizedBox(height: 36.h),
          Container(
            width: dialSize,
            height: dialSize,
            decoration: BoxDecoration(
              color: context.surfaceColor(Colors.white),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(height: 20.h),
          Container(
            width: dialSize * .6,
            height: 12.h,
            decoration: BoxDecoration(
              color: context.surfaceColor(Colors.white),
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
        ],
      ),
    );
  }
}
