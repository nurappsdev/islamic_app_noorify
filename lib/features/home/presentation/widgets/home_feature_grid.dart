import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/features/home/presentation/screens/home_screen.dart';
import 'package:tuhfatul_muslim/features/zikr/data/zikr_progress_store.dart';
import 'package:tuhfatul_muslim/shared/widgets/coming_soon_screen.dart';

class HomeFeatureGrid extends StatelessWidget {
  const HomeFeatureGrid({super.key});

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
    final features = _features(appText);
    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: features.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: 128.h,
            crossAxisSpacing: 11.w,
            mainAxisSpacing: 12.h,
          ),
          itemBuilder: (context, index) =>
              _FeatureTile(feature: features[index]),
        ),
        SizedBox(height: 12.h),
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
    final isDua = feature.routeName == RouteNames.dua;
    final navigate = isDua
        ? () => _showComingSoonDialog(context)
        : feature.routeName == null
        ? null
        : () => Navigator.of(context).pushNamed(feature.routeName!);
    final isZikr = feature.routeName == RouteNames.zikr;

    return InkWell(
      onTap: navigate,
      borderRadius: BorderRadius.circular(11.r),
      child: HomeCard(
        padding: EdgeInsets.symmetric(vertical: 13.h),
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

void _openComingSoon(BuildContext context, String title) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => ComingSoonScreen(title: title)),
  );
}

/// The Dua feature's existing screens/routes are temporarily disabled; this
/// grid tile stays visible but shows a "Coming Soon" message (in the active
/// app language) instead of opening them.
void _showComingSoonDialog(BuildContext context) {
  final appText = AppText.of(context);
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      content: Text(
        appText.comingSoon,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
      ),
      actions: [
        Center(
          child: TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(appText.ok),
          ),
        ),
      ],
    ),
  );
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11.r),
      child: HomeCard(
        padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 9.h),
        child: Row(
          children: [
            Icon(icon, color: context.inkColor(iconColor), size: 24.sp),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                title,
                style: homeSansStyle(context: context, fontSize: 12.sp),
              ),
            ),
            HomeCircleButton(icon: Icons.chevron_right, onPressed: onTap),
          ],
        ),
      ),
    );
  }
}
