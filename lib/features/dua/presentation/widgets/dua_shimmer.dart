import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';

/// Theme-aware loading placeholders for the Dua feature's remote content.
class DuaShimmer extends StatelessWidget {
  const DuaShimmer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
    baseColor: context.surfaceColor(const Color(0xFFE3ECC5)),
    highlightColor: context.surfaceColor(const Color(0xFFF6F9EC)),
    child: child,
  );
}

class _Box extends StatelessWidget {
  const _Box({this.width, required this.height, this.radius = 8});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: context.surfaceColor(Colors.white),
      borderRadius: BorderRadius.circular(radius.r),
    ),
  );
}

/// Skeleton for the Dua dashboard's featured card and category grid.
class DuaDashboardShimmer extends StatelessWidget {
  const DuaDashboardShimmer({super.key});

  @override
  Widget build(BuildContext context) => DuaShimmer(
    child: ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 120.h),
      children: [
        const _Box(height: 38, radius: 20),
        SizedBox(height: 24.h),
        const _Box(width: 120, height: 16),
        SizedBox(height: 12.h),
        const _Box(height: 150, radius: 20),
        SizedBox(height: 24.h),
        const _Box(width: 150, height: 16),
        SizedBox(height: 12.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 4,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: 150.h,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
          ),
          itemBuilder: (_, _) => const _Box(height: 150, radius: 18),
        ),
      ],
    ),
  );
}

/// Skeleton for the Dua reading dashboard: legend, chart, the two metric
/// cards and the first recitation-history rows.
class DuaReadingDashboardShimmer extends StatelessWidget {
  const DuaReadingDashboardShimmer({super.key});

  @override
  Widget build(BuildContext context) => DuaShimmer(
    child: ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
      children: [
        const _Box(height: 36, radius: 10),
        SizedBox(height: 14.h),
        const _Box(height: 212, radius: 18),
        SizedBox(height: 16.h),
        Row(
          children: [
            const Expanded(child: _Box(height: 122, radius: 21)),
            SizedBox(width: 12.w),
            const Expanded(child: _Box(height: 122, radius: 21)),
          ],
        ),
        SizedBox(height: 20.h),
        const _Box(width: 180, height: 16),
        SizedBox(height: 16.h),
        for (var i = 0; i < 4; i++) ...[
          const _Box(height: 31, radius: 10),
          SizedBox(height: 14.h),
        ],
      ],
    ),
  );
}

/// Skeleton for searchable category screens.
class DuaCategoryGridShimmer extends StatelessWidget {
  const DuaCategoryGridShimmer({super.key});

  @override
  Widget build(BuildContext context) => DuaShimmer(
    child: ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 104.h),
      children: [
        const _Box(height: 38, radius: 20),
        SizedBox(height: 24.h),
        const _Box(width: 110, height: 13),
        SizedBox(height: 12.h),
        const _Box(height: 48, radius: 24),
        SizedBox(height: 16.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 6,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: 150.h,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
          ),
          itemBuilder: (_, _) => const _Box(height: 150, radius: 18),
        ),
      ],
    ),
  );
}

/// Skeleton for featured, category-Dua, and plan-detail lists.
class DuaListShimmer extends StatelessWidget {
  const DuaListShimmer({
    super.key,
    this.cardHeight = 84,
    this.itemCount = 6,
    this.showHeader = true,
  });

  final double cardHeight;
  final int itemCount;
  final bool showHeader;

  @override
  Widget build(BuildContext context) => DuaShimmer(
    child: ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 104.h),
      itemCount: itemCount + (showHeader ? 2 : 0),
      separatorBuilder: (_, _) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        if (showHeader && index == 0) {
          return const _Box(height: 38, radius: 20);
        }
        if (showHeader && index == 1) {
          return const _Box(width: 125, height: 13);
        }
        return Container(
          height: cardHeight.h,
          padding: EdgeInsets.all(14.r),
          decoration: BoxDecoration(
            color: context.surfaceColor(Colors.white),
            borderRadius: BorderRadius.circular(18.r),
          ),
          child: Row(
            children: [
              const _Box(width: 44, height: 44, radius: 22),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _Box(width: 150, height: 14, radius: 4),
                    SizedBox(height: 9.h),
                    const _Box(width: 95, height: 11, radius: 4),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

/// Compact skeleton for category/Dua pickers shown in modal sheets.
class DuaPickerShimmer extends StatelessWidget {
  const DuaPickerShimmer({super.key});

  @override
  Widget build(BuildContext context) => DuaShimmer(
    child: ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(16.r),
      itemCount: 5,
      separatorBuilder: (_, _) => SizedBox(height: 10.h),
      itemBuilder: (_, _) => const _Box(height: 58, radius: 16),
    ),
  );
}
