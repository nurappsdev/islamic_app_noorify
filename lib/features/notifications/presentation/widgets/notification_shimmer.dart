import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

import 'package:tuhfatul_muslim/core/theme/app_palette.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';

/// One card-shaped skeleton, sized to match a real notification card, shown
/// at the bottom of the list while the next page loads.
class NotificationCardShimmer extends StatelessWidget {
  const NotificationCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: context.appPalette.shimmerBase,
      highlightColor: context.appPalette.shimmerHighlight,
      child: Container(
        width: double.infinity,
        height: 92.h,
        decoration: BoxDecoration(
          color: context.surfaceColor(Colors.white),
          borderRadius: BorderRadius.circular(16.r),
        ),
      ),
    );
  }
}
