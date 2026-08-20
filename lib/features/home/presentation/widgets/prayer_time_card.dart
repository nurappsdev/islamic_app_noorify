import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/features/home/data/services/prayer_time_service.dart';
import 'package:islami_app_noorify/features/home/domain/prayer_theme_schedule.dart';
import 'package:islami_app_noorify/features/home/presentation/screens/home_screen.dart';

class PrayerTimeCard extends StatefulWidget {
  const PrayerTimeCard({super.key, this.prayerTimeService, this.now});

  final PrayerTimeService? prayerTimeService;
  final DateTime Function()? now;

  @override
  State<PrayerTimeCard> createState() => _PrayerTimeCardState();
}

class _PrayerTimeCardState extends State<PrayerTimeCard> {
  PrayerClockTime _fajr = const PrayerClockTime(hour: 5, minute: 0);
  Timer? _boundaryTimer;

  DateTime _now() => widget.now?.call() ?? bangladeshNow();

  @override
  void initState() {
    super.initState();
    _scheduleNextBoundary();
    _loadFajrAndSchedule();
  }

  Future<void> _loadFajrAndSchedule() async {
    try {
      final service =
          widget.prayerTimeService ?? await AladhanPrayerTimeService.create();
      final date = _now();
      final cachedFajr = service.cachedFajr(date);
      if (mounted && cachedFajr != null) {
        setState(() => _fajr = cachedFajr);
      }

      final fajr = await service.loadFajr(date);
      if (!mounted) return;
      setState(() => _fajr = fajr);
      _scheduleNextBoundary();
    } catch (_) {
      if (mounted) _scheduleNextBoundary();
    }
  }

  void _scheduleNextBoundary() {
    _boundaryTimer?.cancel();
    final now = _now();
    final boundary = nextPrayerThemeBoundary(now: now, fajr: _fajr);
    _boundaryTimer = Timer(boundary.difference(now), () {
      if (!mounted) return;
      final current = _now();
      final dateChanged =
          current.year != now.year ||
          current.month != now.month ||
          current.day != now.day;
      if (dateChanged) {
        _loadFajrAndSchedule();
      } else {
        setState(() {});
        _scheduleNextBoundary();
      }
    });
  }

  @override
  void dispose() {
    _boundaryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 328.h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 310.h,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(color: const Color(0xFFD9DEA8)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(23.r),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      prayerThemeAsset(now: _now(), fajr: _fajr),
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      top: 20.h,
                      left: 20.w,
                      right: 20.w,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '7 Safar 1444 Hijri',
                                style: homeSerifStyle(
                                  fontSize: 14.sp,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 28.w),
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                '7 Srabon 1433',
                                style: homeSerifStyle(
                                  fontSize: 14.sp,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 65.h,
                      left: 34.w,
                      right: 34.w,
                      child: SizedBox(
                        height: 146.h,
                        child: CustomPaint(painter: _PrayerArcPainter()),
                      ),
                    ),
                    Positioned(
                      top: 88.h,
                      right: 51.w,
                      child: Icon(
                        Icons.wb_sunny,
                        size: 40.sp,
                        color: const Color(0xFFFFA328),
                      ),
                    ),
                    Positioned(
                      top: 105.h,
                      left: 0,
                      right: 0,
                      child: Column(
                        children: [
                          Text(
                            '24 July 2026',
                            style: homeSansStyle(
                              fontSize: 15.sp,
                              color: const Color(0xFF5B856F),
                            ),
                          ),
                          Text(
                            '01:37 PM',
                            style: homeSansStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF557D69),
                            ),
                          ),
                          Text(
                            'Mymensingh, Bangladesh',
                            style: homeSansStyle(
                              fontSize: 12.sp,
                              color: const Color(0xFF5B856F),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 176.h,
                      left: 0,
                      right: 0,
                      child: Center(child: _CurrentPrayerBadge()),
                    ),
                    Positioned(
                      left: 13.w,
                      right: 13.w,
                      bottom: 16.h,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: _PrayerEdgeTime(
                              label: 'Sunrise, Trishal',
                              time: 'at 5:23 AM',
                              icon: Icons.wb_sunny_outlined,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _PrayerEdgeTime(
                              label: 'Sunset, Trishal',
                              time: 'at 6:54 PM',
                              icon: Icons.wb_twilight_outlined,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 292.h,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 36.r,
                height: 36.r,
                decoration: const BoxDecoration(
                  color: Color(0xFFE7E56C),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.keyboard_arrow_down, size: 24.sp),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentPrayerBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 195.w,
      height: 68.h,
      padding: EdgeInsets.symmetric(horizontal: 11.w),
      decoration: BoxDecoration(
        color: const Color(0xFFE4EDB6),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFA2B253), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 40.r,
            height: 40.r,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.nights_stay_rounded,
              color: const Color(0xFF638664),
              size: 24.sp,
            ),
          ),
          SizedBox(width: 15.w),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Dhuhr Prayer Time',
                    style: homeSansStyle(fontSize: 14.sp, color: Colors.black),
                  ),
                ),
                SizedBox(height: 6.h),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '12:44 PM – 3:45 PM',
                    style: homeSansStyle(fontSize: 13.sp, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrayerArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 13.r;
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      0,
      size.width - strokeWidth,
      size.height * 2,
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

    canvas.drawArc(rect, 3.14, 3.14, false, basePaint);
    canvas.drawArc(rect, 3.14, 2.32, false, activePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PrayerEdgeTime extends StatelessWidget {
  const _PrayerEdgeTime({
    required this.label,
    required this.time,
    required this.icon,
  });

  final String label;
  final String time;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 31.sp),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: homeSansStyle(fontSize: 13.sp, color: Colors.white),
                ),
              ),
              SizedBox(height: 7.h),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  time,
                  style: homeSansStyle(fontSize: 15.sp, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
