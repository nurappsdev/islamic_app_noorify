import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

import 'package:tuhfatul_muslim/core/theme/app_palette.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';

/// Wraps [child] with the app-wide shimmer sweep used for loading skeletons
/// (same colors as [HomeShimmer]/[QuranShimmer], kept local to this
/// feature).
class LeaderboardShimmer extends StatelessWidget {
  const LeaderboardShimmer({super.key, required this.child});

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

class _ShimmerCircle extends StatelessWidget {
  const _ShimmerCircle({required this.dimension});

  final double dimension;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: dimension,
      height: dimension,
      decoration: BoxDecoration(
        color: context.surfaceColor(Colors.white),
        shape: BoxShape.circle,
      ),
    );
  }
}

/// One podium slot's skeleton: a circle matching [_PodiumSlot]'s avatar ring
/// plus the name/points pill underneath.
class _PodiumSlotShimmer extends StatelessWidget {
  const _PodiumSlotShimmer({required this.dimension});

  final double dimension;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ShimmerCircle(dimension: dimension),
        SizedBox(height: 12.h),
        _ShimmerBox(width: dimension * .8, height: 34.h, radius: 12.r),
      ],
    );
  }
}

/// Full-page skeleton for [LeaderboardScreen] while `GET
/// /leaderboard/top` is loading: the period pill, the three podium slots,
/// the search bar, and a handful of ranked rows, all sized to match the
/// real content so nothing jumps when it swaps in.
class LeaderboardLoadingShimmer extends StatelessWidget {
  const LeaderboardLoadingShimmer({super.key, this.rowCount = 6});

  final int rowCount;

  @override
  Widget build(BuildContext context) {
    return LeaderboardShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _ShimmerBox(width: 90.w, height: 34.h, radius: 14.r),
          SizedBox(height: 18.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(child: _PodiumSlotShimmer(dimension: 64.r)),
              Expanded(child: _PodiumSlotShimmer(dimension: 88.r)),
              Expanded(child: _PodiumSlotShimmer(dimension: 64.r)),
            ],
          ),
          SizedBox(height: 22.h),
          Row(
            children: [
              Expanded(child: _ShimmerBox(height: 44.h, radius: 22.r)),
              SizedBox(width: 8.w),
              _ShimmerBox(width: 44.r, height: 44.r, radius: 22.r),
            ],
          ),
          SizedBox(height: 16.h),
          for (var i = 0; i < rowCount; i++) ...[
            _ShimmerBox(width: double.infinity, height: 60.h, radius: 16.r),
            SizedBox(height: 10.h),
          ],
        ],
      ),
    );
  }
}
