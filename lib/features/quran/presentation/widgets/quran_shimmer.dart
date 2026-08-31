import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

/// Wraps [child] with the app-wide shimmer sweep used for loading skeletons.
class QuranShimmer extends StatelessWidget {
  const QuranShimmer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE3ECC5),
      highlightColor: const Color(0xFFF6F9EC),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Single skeleton row matching the surah/juz `_ListRow` layout: a circular
/// number badge followed by a title line and a subtitle line.
class SurahListRowShimmer extends StatelessWidget {
  const SurahListRowShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return QuranShimmer(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Row(
          children: [
            _ShimmerBox(width: 34.w, height: 34.w, radius: 17.w),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ShimmerBox(width: 140.w, height: 14.h, radius: 4.r),
                  SizedBox(height: 8.h),
                  _ShimmerBox(width: 90.w, height: 11.h, radius: 4.r),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-page skeleton for [SurahListScreen]'s surah/juz tabs.
class SurahListShimmer extends StatelessWidget {
  const SurahListShimmer({super.key, this.itemCount = 8});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return QuranShimmer(
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(0, 4.h, 0, 100.h),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, _) =>
            const Divider(height: 1, color: Colors.white),
        itemBuilder: (_, _) => Padding(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          child: Row(
            children: [
              _ShimmerBox(width: 34.w, height: 34.w, radius: 17.w),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ShimmerBox(width: 140.w, height: 14.h, radius: 4.r),
                    SizedBox(height: 8.h),
                    _ShimmerBox(width: 90.w, height: 11.h, radius: 4.r),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-page skeleton for bookmark/history style card lists.
class QuranCardListShimmer extends StatelessWidget {
  const QuranCardListShimmer({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return QuranShimmer(
      child: ListView.separated(
        padding: EdgeInsets.only(bottom: 20.h),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, _) => SizedBox(height: 9.h),
        itemBuilder: (_, _) => Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ShimmerBox(width: 160.w, height: 14.h, radius: 4.r),
                    SizedBox(height: 8.h),
                    _ShimmerBox(width: 220.w, height: 11.h, radius: 4.r),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-page skeleton for [SurahDetailScreen]: a hero block, a reading-time
/// line, then a stack of ayah-card sized blocks.
class SurahDetailShimmer extends StatelessWidget {
  const SurahDetailShimmer({super.key, this.cardCount = 4});

  final int cardCount;

  @override
  Widget build(BuildContext context) {
    return QuranShimmer(
      child: ListView(
        padding: EdgeInsets.only(top: 4.h, bottom: 24.h),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          Container(
            width: double.infinity,
            height: 210.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22.r),
            ),
          ),
          SizedBox(height: 10.h),
          Center(
            child: _ShimmerBox(width: 140.w, height: 12.h, radius: 4.r),
          ),
          SizedBox(height: 18.h),
          for (var i = 0; i < cardCount; i++) ...[
            Container(
              width: double.infinity,
              height: 130.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
            SizedBox(height: 10.h),
          ],
        ],
      ),
    );
  }
}

/// Full-page skeleton for [FullSurahScreen]'s continuous-text layout: a
/// hero block, a reading-time line, a large block for the Arabic text and a
/// few lines for the current-ayah translation.
class FullSurahShimmer extends StatelessWidget {
  const FullSurahShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return QuranShimmer(
      child: ListView(
        padding: EdgeInsets.fromLTRB(18.w, 4.h, 18.w, 12.h),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          Container(
            width: double.infinity,
            height: 210.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22.r),
            ),
          ),
          SizedBox(height: 10.h),
          Center(
            child: _ShimmerBox(width: 140.w, height: 12.h, radius: 4.r),
          ),
          SizedBox(height: 18.h),
          Container(
            width: double.infinity,
            height: 220.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          SizedBox(height: 16.h),
          _ShimmerBox(width: double.infinity, height: 14.h, radius: 4.r),
          SizedBox(height: 8.h),
          _ShimmerBox(width: double.infinity, height: 14.h, radius: 4.r),
          SizedBox(height: 8.h),
          _ShimmerBox(width: 160.w, height: 14.h, radius: 4.r),
        ],
      ),
    );
  }
}

/// Full-page skeleton for [VerseReaderScreen]'s juz view: a stack of
/// ayah-card sized blocks.
class VerseReaderShimmer extends StatelessWidget {
  const VerseReaderShimmer({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return QuranShimmer(
      child: ListView.separated(
        padding: EdgeInsets.only(top: 12.h, bottom: 24.h),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, _) => SizedBox(height: 10.h),
        itemBuilder: (_, _) => Container(
          width: double.infinity,
          height: 120.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
      ),
    );
  }
}
