import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/features/home/data/services/prayer_time_service.dart';
import 'package:islami_app_noorify/features/home/domain/daily_prayer_times.dart';
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
  DailyPrayerTimes? _times;
  Timer? _boundaryTimer;

  PrayerClockTime get _fajr =>
      _times?.fajr ?? const PrayerClockTime(hour: 5, minute: 0);

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
      final cachedTimes = service.cachedPrayerTimes(date);
      if (mounted && cachedTimes != null) {
        setState(() => _times = cachedTimes);
      }

      final times = await service.loadPrayerTimes(date);
      if (!mounted) return;
      if (times != null) setState(() => _times = times);
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
      height: 319.h,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 5.w),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 301.h,
              child: Container(
                key: const ValueKey('prayer-time-card-surface'),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(color: const Color(0xFFD9DEA8)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(23.r),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const DecoratedBox(
                        key: ValueKey('prayer-time-card-sky'),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFF3EBC7), Color(0xFFFFDFA2)],
                          ),
                        ),
                      ),
                      // Background
                      Image.asset(
                        prayerThemeAsset(now: _now(), fajr: _fajr),
                        fit: BoxFit.cover,
                      ),

                      // DCE8B8 Dome Shape
                      Positioned(
                        top: 87.h,
                        left: 54.w,
                        right: 54.w,
                        child: SizedBox(
                          key: const ValueKey('prayer-time-card-notched-dome'),
                          height: 126.h,
                          child: CustomPaint(painter: _PrayerDomePainter()),
                        ),
                      ),

                      // Hijri Date
                      Positioned(
                        top: 19.h,
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

                      // Prayer Arc
                      Positioned(
                        top: 63.h,
                        left: 33.w,
                        right: 33.w,
                        child: SizedBox(
                          height: 142.h,
                          child: CustomPaint(painter: _PrayerArcPainter()),
                        ),
                      ),

                      // Sun
                      Positioned(
                        top: 84.h,
                        right: 48.w,
                        child: SizedBox.square(
                          dimension: 43.r,
                          child: CustomPaint(painter: _PrayerSunPainter()),
                        ),
                      ),

                      // Date Time Location
                      Positioned(
                        top: 102.h,
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

                      // Current Prayer Badge
                      Positioned(
                        top: 171.h,
                        left: 0,
                        right: 0,
                        child: Center(child: _CurrentPrayerBadge()),
                      ),

                      // Sunrise Sunset
                      Positioned(
                        left: 13.w,
                        right: 13.w,
                        bottom: 15.h,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: _PrayerEdgeTime(
                                label: 'Sunrise, Trishal',
                                time: 'at 5:23 AM',
                                isSunrise: true,
                              ),
                            ),

                            SizedBox(width: 12.w),

                            Expanded(
                              child: _PrayerEdgeTime(
                                label: 'Sunset, Trishal',
                                time: 'at 6:54 PM',
                                isSunrise: false,
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

            // Bottom Arrow Button
            Positioned(
              top: 283.h,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox.square(
                  dimension: 36.r,
                  child: IconButton(
                    tooltip: 'View prayer times',
                    onPressed: () =>
                        Navigator.of(context).pushNamed(RouteNames.prayerTimes),

                    style: IconButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: const Color(0xFFE7E56C),
                      foregroundColor: Colors.black,
                    ),

                    icon: Icon(Icons.keyboard_arrow_down, size: 24.sp),
                  ),
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
      width: 190.w,
      height: 66.h,
      padding: EdgeInsets.symmetric(horizontal: 11.w),
      decoration: BoxDecoration(
        color: const Color(0xFFE4EDB6),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFA2B253), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 39.r,
            height: 39.r,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Padding(
              padding: EdgeInsets.all(5.r),
              child: CustomPaint(painter: _PrayerBadgeIllustrationPainter()),
            ),
          ),
          SizedBox(width: 14.w),
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

class _PrayerSunPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final rayPaint = Paint()
      ..color = const Color(0xFFFFA328)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * .09;

    for (var index = 0; index < 8; index++) {
      final angle = index * math.pi / 4;
      final inner = Offset(
        center.dx + math.cos(angle) * size.width * .34,
        center.dy + math.sin(angle) * size.width * .34,
      );
      final outer = Offset(
        center.dx + math.cos(angle) * size.width * .45,
        center.dy + math.sin(angle) * size.width * .45,
      );
      canvas.drawLine(inner, outer, rayPaint);
    }

    canvas.drawCircle(
      center,
      size.width * .23,
      Paint()..color = const Color(0xFFFFA328),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PrayerBadgeIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final moonPaint = Paint()..color = const Color(0xFFFFC94C);
    final moon = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(size.width * .68, size.height * .27),
          radius: size.width * .18,
        ),
      );
    final cutout = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(size.width * .75, size.height * .21),
          radius: size.width * .17,
        ),
      );
    canvas.drawPath(
      Path.combine(PathOperation.difference, moon, cutout),
      moonPaint,
    );

    final leafPaint = Paint()..color = const Color(0xFF638664);
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * .13,
        size.height * .49,
        size.width * .47,
        size.height * .35,
      ),
      leafPaint,
    );
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * .37,
        size.height * .57,
        size.width * .39,
        size.height * .27,
      ),
      leafPaint,
    );
    canvas.drawCircle(
      Offset(size.width * .18, size.height * .82),
      size.width * .10,
      Paint()..color = const Color(0xFFA5B653),
    );
    canvas.drawCircle(
      Offset(size.width * .80, size.height * .81),
      size.width * .11,
      Paint()..color = const Color(0xFFA5B653),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HorizonTimeIconPainter extends CustomPainter {
  const _HorizonTimeIconPainter({required this.isSunrise});

  final bool isSunrise;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8.r
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final centerX = size.width / 2;
    final center = Offset(centerX, size.height * .48);
    final horizonY = size.height * .72;
    final sunRadius = size.width * .24;

    canvas.drawCircle(center, sunRadius, paint);
    canvas.drawLine(
      Offset(size.width * .09, horizonY),
      Offset(size.width * .91, horizonY),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * .2, horizonY + size.height * .11),
      Offset(size.width * .8, horizonY + size.height * .11),
      paint,
    );

    for (final angle in <double>[-2.75, -2.15, -math.pi / 2, -.99, -.39]) {
      final inner = Offset(
        center.dx + math.cos(angle) * size.width * .32,
        center.dy + math.sin(angle) * size.width * .32,
      );
      final outer = Offset(
        center.dx + math.cos(angle) * size.width * .41,
        center.dy + math.sin(angle) * size.width * .41,
      );
      canvas.drawLine(inner, outer, paint);
    }

    final arrowTop = size.height * .35;
    final arrowBottom = size.height * .59;
    if (isSunrise) {
      canvas.drawLine(
        Offset(centerX, arrowBottom),
        Offset(centerX, arrowTop),
        paint,
      );
      canvas.drawLine(
        Offset(centerX, arrowTop),
        Offset(centerX - size.width * .09, arrowTop + size.height * .09),
        paint,
      );
      canvas.drawLine(
        Offset(centerX, arrowTop),
        Offset(centerX + size.width * .09, arrowTop + size.height * .09),
        paint,
      );
    } else {
      canvas.drawLine(
        Offset(centerX, arrowTop),
        Offset(centerX, arrowBottom),
        paint,
      );
      canvas.drawLine(
        Offset(centerX, arrowBottom),
        Offset(centerX - size.width * .09, arrowBottom - size.height * .09),
        paint,
      );
      canvas.drawLine(
        Offset(centerX, arrowBottom),
        Offset(centerX + size.width * .09, arrowBottom - size.height * .09),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HorizonTimeIconPainter oldDelegate) =>
      oldDelegate.isSunrise != isSunrise;
}

class _PrayerEdgeTime extends StatelessWidget {
  const _PrayerEdgeTime({
    required this.label,
    required this.time,
    required this.isSunrise,
  });

  final String label;
  final String time;
  final bool isSunrise;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: ValueKey(isSunrise ? 'prayer-edge-sunrise' : 'prayer-edge-sunset'),
      height: 46.h,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 36.r,
            height: 38.r,
            child: CustomPaint(
              painter: _HorizonTimeIconPainter(isSunrise: isSunrise),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: homeSansStyle(fontSize: 13.sp, color: Colors.white),
                  ),
                ),
                SizedBox(height: 3.h),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    time,
                    maxLines: 1,
                    style: homeSansStyle(fontSize: 15.sp, color: Colors.white),
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
class _PrayerDomePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFDCE8B8)
      ..style = PaintingStyle.fill;

    final path = Path();

    final notchRadius = size.width * 0.04;

    // Start bottom left
    path.moveTo(
      size.width * 0.08,
      size.height,
    );

    // Left rounded corner
    path.quadraticBezierTo(
      0,
      size.height,
      0,
      size.height * 0.77,
    );

    // Left dome curve
    path.cubicTo(
      size.width * 0.09,
      size.height * 0.25,
      size.width * 0.22,
      0,
      size.width / 2,
      0,
    );

    // Right dome curve
    path.cubicTo(
      size.width * 0.82,
      0,
      size.width * 0.92,
      size.height * 0.30,
      size.width,
      size.height * 0.78,
    );

    // Right rounded corner
    path.quadraticBezierTo(
      size.width,
      size.height,
      size.width * 0.92,
      size.height,
    );

    // Bottom line to notch
    path.lineTo(
      size.width / 2 + notchRadius,
      size.height,
    );


    // Center notch
    path.arcTo(
      Rect.fromCircle(
        center: Offset(
          size.width / 2,
          size.height,
        ),
        radius: notchRadius,
      ),
      0,
      -math.pi,
      false,
    );


    // Back to left
    path.lineTo(
      size.width * 0.08,
      size.height,
    );

    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}