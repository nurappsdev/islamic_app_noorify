import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';

/// Wraps [child] with the app-wide shimmer sweep used for loading skeletons
/// (same colors as [QuranShimmer]/[HomeShimmer], kept local to this feature).
class AsmaHusnaShimmer extends StatelessWidget {
  const AsmaHusnaShimmer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: context.surfaceColor(Color(0xFFE3ECC5)),
      highlightColor: context.surfaceColor(Color(0xFFF6F9EC)),
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

/// Skeleton for a single [AsmaNameCard] while its name/detail data loads:
/// the same card shape, with the Arabic/transliteration/meaning lines, the
/// details pill, and the two bottom circles all rendered as shimmer blocks.
/// Used standalone for [AsmaHusnaIntroScreen]'s single preview card, and
/// repeated by [AsmaHusnaListShimmer] for the full list.
class AsmaNameCardShimmer extends StatelessWidget {
  const AsmaNameCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return AsmaHusnaShimmer(
      child: Container(
        padding: EdgeInsets.fromLTRB(14.w, 16.h, 14.w, 18.h),
        decoration: BoxDecoration(
          color: context.surfaceColor(Colors.white),
          borderRadius: BorderRadius.circular(28.r),
        ),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: .92,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ShimmerBox(width: 90.w, height: 26.h, radius: 6.r),
                    SizedBox(height: 10.h),
                    _ShimmerBox(width: 110.w, height: 19.h, radius: 6.r),
                    SizedBox(height: 8.h),
                    _ShimmerBox(width: 100.w, height: 14.h, radius: 4.r),
                    SizedBox(height: 6.h),
                    _ShimmerBox(width: 150.w, height: 11.h, radius: 4.r),
                    SizedBox(height: 14.h),
                    _ShimmerBox(width: 130.w, height: 30.h, radius: 20.r),
                  ],
                ),
              ),
            ),
            SizedBox(height: 14.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ShimmerBox(width: 42.r, height: 42.r, radius: 21.r),
                _ShimmerBox(width: 46.r, height: 46.r, radius: 23.r),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-page skeleton for [AsmaHusnaListScreen] while `GET /asma-ul-husna`
/// is loading — matches its `ListView.separated` padding/gap exactly so the
/// skeleton doesn't jump when the real cards swap in.
class AsmaHusnaListShimmer extends StatelessWidget {
  const AsmaHusnaListShimmer({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 28.h),
      itemCount: itemCount,
      separatorBuilder: (_, _) => SizedBox(height: 20.h),
      itemBuilder: (_, _) => const AsmaNameCardShimmer(),
    );
  }
}

/// Full-page skeleton for [AsmaNameDetailScreen] while `GET
/// /asma-ul-husna/{id}` is loading: the centered name header, then a few
/// paragraph-width lines standing in for the explanation text.
class AsmaNameDetailShimmer extends StatelessWidget {
  const AsmaNameDetailShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return AsmaHusnaShimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(vertical: 24.h),
        child: Column(
          children: [
            _ShimmerBox(width: 70.w, height: 30.h, radius: 6.r),
            SizedBox(height: 14.h),
            _ShimmerBox(width: 120.w, height: 22.h, radius: 6.r),
            SizedBox(height: 8.h),
            _ShimmerBox(width: 100.w, height: 15.h, radius: 4.r),
            SizedBox(height: 10.h),
            _ShimmerBox(width: 200.w, height: 13.h, radius: 4.r),
            SizedBox(height: 28.h),
            for (var i = 0; i < 5; i++) ...[
              _ShimmerBox(width: double.infinity, height: 13.h, radius: 4.r),
              SizedBox(height: 10.h),
            ],
            _ShimmerBox(width: 180.w, height: 13.h, radius: 4.r),
          ],
        ),
      ),
    );
  }
}
