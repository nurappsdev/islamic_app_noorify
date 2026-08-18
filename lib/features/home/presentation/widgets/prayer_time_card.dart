import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_color.dart';
import 'package:islami_app_noorify/features/home/presentation/screens/home_screen.dart';

class PrayerTimeCard extends StatelessWidget {
  const PrayerTimeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      padding: EdgeInsets.zero,
      borderColor: const Color(0xFFE9E4B6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.r),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset('assets/images/theme2.png', fit: BoxFit.cover),
            ),
            SizedBox(
              height: 191.h,
              child: Stack(
                children: [
                  Positioned(
                    top: 42.h,
                    left: 18.w,
                    right: 18.w,
                    child: SizedBox(
                      height: 98.h,
                      child: CustomPaint(painter: _PrayerArcPainter()),
                    ),
                  ),
                  Positioned(
                    top: 58.h,
                    right: 39.w,
                    child: Icon(
                      Icons.wb_sunny,
                      color: const Color(0xFFFFAA2B),
                      size: 28.sp,
                    ),
                  ),
                  Positioned(
                    top: 10.h,
                    left: 13.w,
                    right: 13.w,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '7 Safar 1446 Hijri',
                          style: homeSerifStyle(fontSize: 10.sp),
                        ),
                        Text(
                          '7 Sunbon 1433',
                          style: homeSerifStyle(fontSize: 10.sp),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 82.h,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        Text(
                          '24 July 2026',
                          style: homeSansStyle(
                            fontSize: 10.sp,
                            color: AppColor.primary,
                          ),
                        ),
                        Text(
                          '01: 37 PM',
                          style: homeSansStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColor.primary,
                          ),
                        ),
                        Text(
                          'Mymensingh, Bangladesh',
                          style: homeSansStyle(
                            fontSize: 9.sp,
                            color: AppColor.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 129.h,
                    left: 0,
                    right: 0,
                    child: Center(child: _CurrentPrayerBadge()),
                  ),
                  Positioned(
                    bottom: 7.h,
                    left: 13.w,
                    right: 13.w,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        _PrayerEdgeTime(
                          label: 'Sunrise, Tishal',
                          time: 'at 5:23 AM',
                        ),
                        _PrayerEdgeTime(
                          label: 'Sunset, Trishal',
                          time: 'at 6:54 PM',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: -2.h,
              left: 0,
              right: 0,
              child: Center(
                child: HomeCircleButton(
                  icon: Icons.keyboard_arrow_down,
                  size: 28.r,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentPrayerBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5D7),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26.r,
            height: 26.r,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(7.r),
            ),
            child: Icon(
              Icons.cloud_queue,
              color: AppColor.primary,
              size: 16.sp,
            ),
          ),
          SizedBox(width: 8.w),
          Column(
            children: [
              Text('Dhuhr Prayer Time', style: homeSansStyle(fontSize: 10.sp)),
              SizedBox(height: 2.h),
              Text(
                '12:44 PM - 3:45 PM',
                style: homeSansStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrayerArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height * 1.95);
    final basePaint = Paint()
      ..color = const Color(0xFFECE9D4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final activePaint = Paint()
      ..color = const Color(0xFF5D8067)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 3.12, 3.08, false, basePaint);
    canvas.drawArc(rect, 3.12, 2.16, false, activePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PrayerEdgeTime extends StatelessWidget {
  const _PrayerEdgeTime({required this.label, required this.time});

  final String label;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.wb_twilight_outlined, color: Colors.white, size: 18.sp),
        Text(
          label,
          style: homeSansStyle(fontSize: 8.sp, color: Colors.white),
        ),
        Text(
          time,
          style: homeSansStyle(fontSize: 9.sp, color: Colors.white),
        ),
      ],
    );
  }
}
