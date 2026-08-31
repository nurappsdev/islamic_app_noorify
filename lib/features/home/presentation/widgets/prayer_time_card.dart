import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/home/data/services/prayer_time_service.dart';
import 'package:islami_app_noorify/features/home/domain/current_prayer.dart';
import 'package:islami_app_noorify/features/home/domain/daily_prayer_times.dart';
import 'package:islami_app_noorify/features/home/domain/prayer_theme_schedule.dart';
import 'package:islami_app_noorify/features/home/presentation/screens/home_screen.dart';
import 'package:islami_app_noorify/features/home/presentation/widgets/prayer_arc_sun_painter.dart';

part 'prayer_time_card_widgets.dart';
part 'prayer_time_card_painters.dart';

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
  Timer? _edgeTimeTimer;
  Timer? _clockTimer;
  bool _showSunriseAndSunset = false;

  PrayerClockTime get _fajr =>
      _times?.fajr ?? const PrayerClockTime(hour: 5, minute: 0);

  DateTime _now() => widget.now?.call() ?? bangladeshNow();

  double get _dayProgress {
    final times = _times;
    return times == null ? 0 : dayProgress(_now(), times);
  }

  String _formattedDate(AppText appText) {
    final now = _now();
    return '${now.day} ${appText.monthNames[now.month - 1]} ${now.year}';
  }

  String _formattedTime() => formatPrayerTime(
    PrayerClockTime(hour: _now().hour, minute: _now().minute),
  );

  @override
  void initState() {
    super.initState();
    _scheduleNextBoundary();
    _loadFajrAndSchedule();
    _edgeTimeTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      setState(() => _showSunriseAndSunset = !_showSunriseAndSunset);
    });
    // Keeps the live clock and sun-progress indicator in sync with the
    // device's system clock.
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      setState(() {});
    });
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
    _edgeTimeTimer?.cancel();
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
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
                      // DCE8B8 Dome Shape
                      Positioned(
                        top: 90.h,
                        left: 54.w,
                        right: 54.w,
                        child: SizedBox(
                          key: const ValueKey('prayer-time-card-notched-dome'),
                          height: 126.h,
                          child: Image.asset(
                            'assets/images/backImg.png',
                            fit: BoxFit.fill,
                          ),
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
                                  _times?.hijriDate ??
                                      appText.hijriDatePlaceholder,
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
                                  appText.bengaliDatePlaceholder,
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

                      // Prayer Arc + Sun (position/progress track the actual
                      // time of day between sunrise and sunset).
                      Positioned(
                        top: 72.h,
                        left: 33.w,
                        right: 33.w,
                        child: SizedBox(
                          height: 142.h,
                          child: PrayerDayProgress(progress: _dayProgress),
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
                              _formattedDate(appText),
                              style: homeSansStyle(
                                fontSize: 15.sp,
                                color: const Color(0xFF5B856F),
                              ),
                            ),

                            Text(
                              _formattedTime(),
                              style: homeSansStyle(
                                fontSize: 22.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF557D69),
                              ),
                            ),

                            Text(
                              appText.locationPlaceholder,
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
                        child: Center(
                          child: _CurrentPrayerBadge(
                            times: _times,
                            now: _now(),
                          ),
                        ),
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
                                label: '${appText.sunrise}, ${appText.trishal}',
                                time: _times != null
                                    ? formatPrayerTime(_times!.sunrise)
                                    : appText.sunriseTimePlaceholder,
                                isSunrise: true,
                                secondaryLabel: appText.sehri,
                                secondaryTime: _times != null
                                    ? formatPrayerTime(_times!.fajr)
                                    : appText.sunriseTimePlaceholder,
                                showPrimary: _showSunriseAndSunset,
                              ),
                            ),

                            SizedBox(width: 12.w),

                            Expanded(
                              child: _PrayerEdgeTime(
                                label: '${appText.sunset}, ${appText.trishal}',
                                time: _times != null
                                    ? formatPrayerTime(_times!.sunset)
                                    : appText.sunsetTimePlaceholder,
                                isSunrise: false,
                                secondaryLabel: appText.iftar,
                                secondaryTime: _times != null
                                    ? formatPrayerTime(_times!.maghrib)
                                    : appText.sunsetTimePlaceholder,
                                showPrimary: _showSunriseAndSunset,
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
                    tooltip: appText.viewPrayerTimes,
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
