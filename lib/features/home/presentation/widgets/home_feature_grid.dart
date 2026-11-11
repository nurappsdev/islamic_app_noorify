import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/features/home/presentation/screens/home_screen.dart';
import 'package:tuhfatul_muslim/features/zikr/data/zikr_progress_store.dart';

class HomeFeatureGrid extends StatelessWidget {
  const HomeFeatureGrid({
    super.key,
    this.columnMajor = false,
    this.webStyle = false,
  });

  /// Web's reference design reads each vertical column top-to-bottom before
  /// moving to the next one. Android/iOS retain their existing row order.
  final bool columnMajor;

  /// Uses the reference Web dashboard's six compact, horizontal shortcuts.
  /// Mobile retains its original two-column, portrait cards.
  final bool webStyle;

  static List<_HomeFeature> _features(AppText appText) => [
    _HomeFeature(
      appText.categoryQuran,
      Icons.menu_book_outlined,
      const Color(0xFFA5B58F),
      imagePath: 'assets/homeImg/quranImg.png',
      routeName: RouteNames.quran,
    ),
    _HomeFeature(
      appText.categoryHadith,
      Icons.local_library,
      const Color(0xFF20B20F),
      imagePath: 'assets/homeImg/haditImg.png',
      routeName: RouteNames.hadith,
    ),
    _HomeFeature(
      appText.featureQuizAndLearn,
      Icons.quiz_outlined,
      const Color(0xFFFF9D13),
      imagePath: 'assets/homeImg/quizImg.png',
      routeName: RouteNames.winQuiz,
    ),
    _HomeFeature(
      appText.featureAsmaUlHusna,
      Icons.workspace_premium,
      const Color(0xFF37C915),
      imagePath: 'assets/homeImg/asmaImg.png',
      routeName: RouteNames.asma,
    ),
    _HomeFeature(
      appText.featureDijpr,
      Icons.nightlight_round,
      const Color(0xFFFFD21E),
      imagePath: 'assets/homeImg/zikrImg.png',
      routeName: RouteNames.zikr,
    ),
    _HomeFeature(
      appText.featureDua,
      Icons.volunteer_activism,
      const Color(0xFFFF7D67),
      imagePath: 'assets/homeImg/duaImg.png',
      routeName: RouteNames.dua,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final baseFeatures = _features(appText);
    final features = columnMajor
        ? [
            // GridView fills left-to-right by rows, so interleave the two
            // desired columns: Quran/Hadith/Quiz | Asma/Zikr/Dua.
            baseFeatures[0],
            baseFeatures[3],
            baseFeatures[1],
            baseFeatures[4],
            baseFeatures[2],
            baseFeatures[5],
          ]
        : baseFeatures;
    return LayoutBuilder(
      builder: (context, constraints) {
        final webColumns = constraints.maxWidth >= 880 ? 3 : 2;
        return Column(
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: features.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: webStyle ? webColumns : 2,
                mainAxisExtent: webStyle ? 128 : 128.h,
                crossAxisSpacing: webStyle ? 18 : 11.w,
                mainAxisSpacing: webStyle ? 18 : 12.h,
              ),
              itemBuilder: (context, index) => webStyle
                  ? _WebFeatureTile(feature: features[index])
                  : _FeatureTile(feature: features[index]),
            ),
            SizedBox(height: webStyle ? 0 : 12.h),
            // _LinkTile(
            //   title: appText.zakatCalculator,
            //   icon: Icons.price_check,
            //   iconColor: context.inkColor(Color(0xFF0DA334)),
            //   onTap: () => _openComingSoon(context, appText.zakatCalculator),
            // ),
            // SizedBox(height: 6.h),
            // _LinkTile(
            //   title: appText.ageCalculate,
            //   icon: Icons.calculate,
            //   iconColor: const Color(0xFFAAB781),
            //   onTap: () => _openComingSoon(context, appText.ageCalculate),
            // ),
          ],
        );
      },
    );
  }
}

class _HomeFeature {
  const _HomeFeature(
    this.title,
    this.icon,
    this.color, {
    this.imagePath,
    this.routeName,
  });

  final String title;
  final IconData icon;
  final Color color;
  final String? imagePath;
  final String? routeName;
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.feature});

  final _HomeFeature feature;

  @override
  Widget build(BuildContext context) {
    final navigate = feature.routeName == null
        ? null
        : () => Navigator.of(context).pushNamed(feature.routeName!);
    final isZikr = feature.routeName == RouteNames.zikr;

    return InkWell(
      onTap: navigate,
      borderRadius: BorderRadius.circular(11.r),
      child: HomeCard(
        // Ubuntu's glyph metrics are slightly taller than the previous default
        // font. Keeping one extra logical pixel of vertical room prevents the
        // fixed-height grid tile from overflowing on compact devices.
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isZikr
                ? _ZikrIconWithBadge(
                    icon: feature.icon,
                    color: feature.color,
                    imagePath: feature.imagePath,
                  )
                : _FeatureImage(
                    imagePath: feature.imagePath,
                    fallbackIcon: feature.icon,
                    color: feature.color,
                  ),
            SizedBox(height: 9.h),
            Text(
              feature.title,
              style: homeSerifStyle(
                context: context,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 10.h),
            HomeCircleButton(icon: Icons.chevron_right, onPressed: navigate),
          ],
        ),
      ),
    );
  }
}

/// The wide-screen shortcut cards echo the reference composition: artwork on
/// the left, a clear destination label, and a single directional affordance.
/// This is intentionally separate from [_FeatureTile] so phone dimensions and
/// typography are never affected by a Web-only polish pass.
class _WebFeatureTile extends StatelessWidget {
  const _WebFeatureTile({required this.feature});

  final _HomeFeature feature;

  @override
  Widget build(BuildContext context) {
    final navigate = feature.routeName == null
        ? null
        : () => Navigator.of(context).pushNamed(feature.routeName!);
    final isZikr = feature.routeName == RouteNames.zikr;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: navigate,
        borderRadius: BorderRadius.circular(18),
        child: HomeCard(
          radius: 18,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          borderColor: context.lineColor(const Color(0xFFD7E7B7)),
          shadows: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          child: Row(
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: Center(
                  child: isZikr
                      ? _ZikrIconWithBadge(
                          icon: feature.icon,
                          color: feature.color,
                          imagePath: feature.imagePath,
                        )
                      : _FeatureImage(
                          imagePath: feature.imagePath,
                          fallbackIcon: feature.icon,
                          color: feature.color,
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  feature.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: homeSerifStyle(
                    context: context,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              HomeCircleButton(icon: Icons.chevron_right, onPressed: navigate),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureImage extends StatelessWidget {
  const _FeatureImage({
    required this.imagePath,
    required this.fallbackIcon,
    required this.color,
  });

  final String? imagePath;
  final IconData fallbackIcon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fallback = Icon(
      fallbackIcon,
      color: context.inkColor(color),
      size: 28.sp,
    );
    if (imagePath == null) return fallback;

    return SizedBox(
      width: 36.w,
      height: 36.h,
      child: Image.asset(
        imagePath!,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}

/// The grid's Zikr icon with a live badge of the Home Screen Zikr section's
/// total count (Prayer Zikr 1 & 2, from Hive). Reacts immediately to a new
/// count or a reset, with no restart or manual refresh.
class _ZikrIconWithBadge extends StatelessWidget {
  const _ZikrIconWithBadge({
    required this.icon,
    required this.color,
    this.imagePath,
  });

  final IconData icon;
  final Color color;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, int>>(
      valueListenable: ZikrProgressStore.instance,
      builder: (context, _, _) {
        final total = ZikrProgressStore.instance.totalCount;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            _FeatureImage(
              imagePath: imagePath,
              fallbackIcon: icon,
              color: color,
            ),
            if (total > 0)
              Positioned(
                right: -8.w,
                top: -4.h,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6E8B3D),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    context.localizedDigits('$total'),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
