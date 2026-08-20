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
        borderRadius: BorderRadius.circular(11.r),
        child: Stack(
          children:[]
        ),
      ),
    );
  }
}

class _CurrentPrayerBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5D7),
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .08),
            blurRadius: 5.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 25.r,
            height: 25.r,
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
          SizedBox(width: 7.w),
          Column(
            children: [
              Text('Dhuhr Prayer Time', style: homeSansStyle(fontSize: 9.sp)),
              SizedBox(height: 2.h),
              Text(
                '12:44 PM - 3:45 PM',
                style: homeSansStyle(
                  fontSize: 8.sp,
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
    final strokeWidth = size.shortestSide * .085;
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth * .1,
      size.width - strokeWidth,
      size.height * 1.93,
    );
    final basePaint = Paint()
      ..color = const Color(0xFFECE9D4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final activePaint = Paint()
      ..color = const Color(0xFF5D8067)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 3.13, 3.0, false, basePaint);
    canvas.drawArc(rect, 3.13, 2.22, false, activePaint);
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
