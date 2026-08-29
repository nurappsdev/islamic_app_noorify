import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/home/data/services/prayer_time_service.dart';
import 'package:islami_app_noorify/features/home/domain/daily_prayer_times.dart';
import 'package:islami_app_noorify/features/home/presentation/screens/home_screen.dart';

class ProhibitedPrayerTimesCard extends StatefulWidget {
  const ProhibitedPrayerTimesCard({
    super.key,
    this.prayerTimeService,
    this.now,
  });

  final PrayerTimeService? prayerTimeService;
  final DateTime Function()? now;

  @override
  State<ProhibitedPrayerTimesCard> createState() =>
      _ProhibitedPrayerTimesCardState();
}

class _ProhibitedPrayerTimesCardState extends State<ProhibitedPrayerTimesCard> {
  DailyPrayerTimes? _times;

  DateTime _now() => widget.now?.call() ?? bangladeshNow();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final service =
          widget.prayerTimeService ?? await AladhanPrayerTimeService.create();
      final date = _now();
      final cached = service.cachedPrayerTimes(date);
      if (mounted && cached != null) setState(() => _times = cached);

      final times = await service.loadPrayerTimes(date);
      if (mounted && times != null) setState(() => _times = times);
    } catch (_) {
      // Keep showing whatever was loaded (or nothing) — the card falls back
      // to placeholders below.
    }
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final times = _times;
    final windows = times == null
        ? null
        : ProhibitedPrayerWindows.fromDailyTimes(times);
    return HomeCard(
      padding: EdgeInsets.fromLTRB(10.w, 10.h, 10.w, 10.h),
      backgroundColor: const Color(0xFFFFF4F4),
      borderColor: const Color(0xFFFF4B4B),
      child: Column(
        children: [
          Text(
            appText.prohibitedPrayerTimes,
            style: homeSansStyle(fontSize: 14.sp),
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              _ForbiddenTime(
                title: appText.sunrise,
                value: windows?.sunrise.formatted ?? '--:-- – --:--',
              ),
              _ForbiddenTime(
                title: appText.jawaal,
                value: windows?.zawal.formatted ?? '--:-- – --:--',
              ),
              _ForbiddenTime(
                title: appText.sunset,
                value: windows?.sunset.formatted ?? '--:-- – --:--',
              ),
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
        padding: EdgeInsets.symmetric(vertical: 9.h, horizontal: 4.w),
        decoration: BoxDecoration(
          color: const Color(0xFFFFD8D8),
          borderRadius: BorderRadius.circular(7.r),
        ),
        child: Column(
          children: [
            Text(title, style: homeSansStyle(fontSize: 10.sp)),
            SizedBox(height: 7.h),
            FittedBox(
              child: Text(
                value,
                style: homeSansStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
