import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/features/home/presentation/screens/home_screen.dart';

class HomeFeatureGrid extends StatelessWidget {
  const HomeFeatureGrid({super.key});

  static const _features = [
    _HomeFeature('Quran', Icons.menu_book_outlined, Color(0xFFA5B58F)),
    _HomeFeature('Hadith', Icons.local_library, Color(0xFF20B20F)),
    _HomeFeature('Dua', Icons.volunteer_activism, Color(0xFFFF7D67)),
    _HomeFeature('Dijpr', Icons.nightlight_round, Color(0xFFFFD21E)),
    _HomeFeature('Asma-ul Husna', Icons.workspace_premium, Color(0xFF37C915)),
    _HomeFeature('Find Mosque', Icons.mosque, Color(0xFFFF9D13)),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _features.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: 128.h,
            crossAxisSpacing: 11.w,
            mainAxisSpacing: 12.h,
          ),
          itemBuilder: (context, index) =>
              _FeatureTile(feature: _features[index]),
        ),
        SizedBox(height: 12.h),
        const _LinkTile(
          title: 'Zakat Calculator',
          icon: Icons.price_check,
          iconColor: Color(0xFF0DA334),
        ),
        SizedBox(height: 6.h),
        const _LinkTile(
          title: 'Age Calculate',
          icon: Icons.calculate,
          iconColor: Color(0xFFAAB781),
        ),
      ],
    );
  }
}

class _HomeFeature {
  const _HomeFeature(this.title, this.icon, this.color);

  final String title;
  final IconData icon;
  final Color color;
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.feature});

  final _HomeFeature feature;

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      padding: EdgeInsets.symmetric(vertical: 13.h),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(feature.icon, color: feature.color, size: 28.sp),
          SizedBox(height: 9.h),
          Text(feature.title, style: homeSerifStyle(fontSize: 12.sp)),
          SizedBox(height: 10.h),
          const HomeCircleButton(icon: Icons.chevron_right),
        ],
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
