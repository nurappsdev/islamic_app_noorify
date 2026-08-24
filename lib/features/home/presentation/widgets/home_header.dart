import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/home/presentation/screens/home_screen.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Row(
      children: [
        CircleAvatar(
          radius: 19.r,
          backgroundColor: const Color(0xFFE8EBC9),
          backgroundImage: const AssetImage('assets/images/logo.png'),
        ),
        SizedBox(width: 7.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appText.competitorName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: homeSansStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                appText.greeting,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: homeSansStyle(fontSize: 8.sp),
              ),
            ],
          ),
        ),
        SizedBox.square(
          dimension: 32.r,
          child: IconButton(
            tooltip: appText.timer,
            onPressed: () {},
            padding: EdgeInsets.zero,
            icon: Icon(
              Icons.timer_outlined,
              color: AppColor.primary,
              size: 20.sp,
            ),
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            SizedBox.square(
              dimension: 36.r,
              child: IconButton(
                tooltip: appText.notifications,
                onPressed: () {},
                padding: EdgeInsets.zero,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFDDE8AE),
                  foregroundColor: AppColor.primary,
                ),
                icon: Icon(Icons.notifications_none, size: 20.sp),
              ),
            ),
            Positioned(
              top: 6.h,
              right: 8.w,
              child: Container(
                width: 9.r,
                height: 9.r,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6969),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.2),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
