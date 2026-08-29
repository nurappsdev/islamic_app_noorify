import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/features/home/presentation/widgets/amal_tracker_card.dart';
import 'package:islami_app_noorify/features/home/presentation/widgets/home_bottom_nav.dart';
import 'package:islami_app_noorify/features/home/presentation/widgets/home_feature_grid.dart';
import 'package:islami_app_noorify/features/home/presentation/widgets/home_header.dart';
import 'package:islami_app_noorify/features/home/presentation/widgets/home_progress_section.dart';
import 'package:islami_app_noorify/features/home/presentation/widgets/prayer_time_card.dart';
import 'package:islami_app_noorify/features/home/presentation/widgets/prohibited_prayer_times_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(9.w, 6.h, 9.w, 92.h),
              child: Column(
                children: [
                  const HomeHeader(),
                  SizedBox(height: 10.h),
                  const AmalTrackerCard(),
                  SizedBox(height: 16.h),
                   const PrayerTimeCard(),
                  SizedBox(height: 24.h),
                  const ProhibitedPrayerTimesCard(),
                  SizedBox(height: 14.h),
                  const HomeProgressSection(),
                  SizedBox(height: 10.h),
                  const HomeFeatureGrid(),
                ],
              ),
            ),
            const Align(
              alignment: Alignment.bottomCenter,
              child: HomeBottomNav(),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeCard extends StatelessWidget {
  const HomeCard({
    super.key,
    required this.child,
    this.padding,
    this.borderColor,
    this.backgroundColor = Colors.white,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(11.r),
        border: Border.all(color: borderColor ?? const Color(0xFFE4E8C8)),
      ),
      child: child,
    );
  }
}

TextStyle homeSerifStyle({
  double? fontSize,
  FontWeight? fontWeight,
  Color color = const Color(0xFF1F2B1C),
}) {
  return TextStyle(
    color: color,
    fontSize: fontSize,
    fontFamily: 'Times New Roman',
    fontStyle: FontStyle.italic,
    fontWeight: fontWeight,
  );
}

TextStyle homeSansStyle({
  double? fontSize,
  FontWeight? fontWeight,
  Color color = const Color(0xFF233021),
}) {
  return TextStyle(color: color, fontSize: fontSize, fontWeight: fontWeight);
}

class HomeCircleButton extends StatelessWidget {
  const HomeCircleButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size ?? 25.r,
      child: IconButton(
        onPressed: onPressed ?? () {},
        style: IconButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: const Color(0xFFDDE8AE),
          foregroundColor: AppColor.primary,
        ),
        icon: Icon(icon, size: 15.sp),
      ),
    );
  }
}
