import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/home/presentation/screens/home_screen.dart';

class HomeFeatureGrid extends StatelessWidget {
  const HomeFeatureGrid({super.key});

  static List<_HomeFeature> _features(AppText appText) => [
    _HomeFeature(
      appText.categoryQuran,
      Icons.menu_book_outlined,
      const Color(0xFFA5B58F),
    ),
    _HomeFeature(
      appText.categoryHadith,
      Icons.local_library,
      const Color(0xFF20B20F),
    ),
    _HomeFeature(
      appText.featureDua,
      Icons.volunteer_activism,
      const Color(0xFFFF7D67),
    ),
    _HomeFeature(
      appText.featureDijpr,
      Icons.nightlight_round,
      const Color(0xFFFFD21E),
    ),
    _HomeFeature(
      appText.featureAsmaUlHusna,
      Icons.workspace_premium,
      const Color(0xFF37C915),
    ),
    _HomeFeature(
      appText.featureQuizAndLearn,
      Icons.quiz_outlined,
      const Color(0xFFFF9D13),
      routeName: RouteNames.winQuiz,
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
        _LinkTile(
          title: appText.zakatCalculator,
          icon: Icons.price_check,
          iconColor: const Color(0xFF0DA334),
        ),
        SizedBox(height: 6.h),
        _LinkTile(
          title: appText.ageCalculate,
          icon: Icons.calculate,
          iconColor: const Color(0xFFAAB781),
        ),
      ],
    );
  }
}

class _HomeFeature {
  const _HomeFeature(this.title, this.icon, this.color, {this.routeName});

  final String title;
  final IconData icon;
  final Color color;
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

    return InkWell(
      onTap: navigate,
      borderRadius: BorderRadius.circular(11.r),
      child: HomeCard(
        padding: EdgeInsets.symmetric(vertical: 13.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(feature.icon, color: feature.color, size: 28.sp),
            SizedBox(height: 9.h),
            Text(feature.title, style: homeSerifStyle(fontSize: 12.sp)),
            SizedBox(height: 10.h),
            HomeCircleButton(icon: Icons.chevron_right, onPressed: navigate),
          ],
        ),
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.title,
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 9.h),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(title, style: homeSansStyle(fontSize: 12.sp)),
          ),
          const HomeCircleButton(icon: Icons.chevron_right),
        ],
      ),
    );
  }
}
