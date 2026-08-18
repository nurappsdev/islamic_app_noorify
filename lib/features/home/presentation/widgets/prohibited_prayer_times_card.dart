import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/features/home/presentation/screens/home_screen.dart';

class ProhibitedPrayerTimesCard extends StatelessWidget {
  const ProhibitedPrayerTimesCard({super.key});

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      padding: EdgeInsets.fromLTRB(10.w, 10.h, 10.w, 9.h),
      backgroundColor: const Color(0xFFFFF4F4),
      borderColor: const Color(0xFFFF4B4B),
      child: Column(
        children: [
          Text(
            'Prohibited Prayer Times',
            style: homeSansStyle(fontSize: 12.sp),
          ),
          SizedBox(height: 9.h),
          Row(
            children: const [
              _ForbiddenTime(title: 'Sunrise', value: '05:21 - 05:36 PM'),
              _ForbiddenTime(title: 'Jawaal', value: '12:03 - 12:05 PM'),
              _ForbiddenTime(title: 'Sunset', value: '06:34 - 06:48 PM'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ForbiddenTime extends StatelessWidget {
  const _ForbiddenTime({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 3.w),
        padding: EdgeInsets.symmetric(vertical: 7.h),
        decoration: BoxDecoration(
          color: const Color(0xFFFFD8D8),
          borderRadius: BorderRadius.circular(7.r),
        ),
        child: Column(
          children: [
            Text(title, style: homeSansStyle(fontSize: 9.sp)),
            SizedBox(height: 6.h),
            FittedBox(
              child: Text(value, style: homeSansStyle(fontSize: 8.sp)),
            ),
          ],
        ),
      ),
    );
  }
}
