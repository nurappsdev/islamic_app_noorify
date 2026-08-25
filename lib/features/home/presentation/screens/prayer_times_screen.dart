import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/home/data/services/prayer_time_service.dart';
import 'package:islami_app_noorify/features/home/domain/current_prayer.dart';
import 'package:islami_app_noorify/features/home/domain/daily_prayer_times.dart';
import 'package:islami_app_noorify/features/home/domain/prayer_theme_schedule.dart';
import 'package:islami_app_noorify/features/alarm/presentation/screens/set_alarm_screen.dart';
import 'package:islami_app_noorify/features/alarm/presentation/screens/set_all_alarm_screen.dart';
import 'package:islami_app_noorify/features/home/presentation/bloc/prayer_times_bloc.dart';
import 'package:islami_app_noorify/features/home/presentation/widgets/prayer_arc_sun_painter.dart';

class PrayerTimesScreen extends StatelessWidget {
  const PrayerTimesScreen({super.key, this.prayerTimeService, this.now});

  final PrayerTimeService? prayerTimeService;
  final DateTime Function()? now;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final bloc = PrayerTimesBloc(
          prayerTimeService: prayerTimeService,
          now: now,
        )..add(const LoadPrayerTimes());
        if (now == null) bloc.add(const StartClock());
        return bloc;
      },
      child: const _PrayerTimesView(),
    );
  }
}

class _PrayerTimesView extends StatelessWidget {
  const _PrayerTimesView();

  static const _olive = Color(0xFF8D9B70);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PrayerTimesBloc>().state;
    final active = state.times == null
        ? null
        : currentPrayerPeriod(state.now, state.times!);
    return Scaffold(
      backgroundColor: _olive,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(
              height: 306.h,
              child: _PrayerSummaryHeader(
                now: state.now,
                times: state.times,
                active: active,
                olive: _olive,
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(15.w, 20.h, 15.w, 18.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCFDF8),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(27.r),
                  ),
                ),
                child: _PrayerList(times: state.times, active: active),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrayerSummaryHeader extends StatelessWidget {
  const _PrayerSummaryHeader({
    required this.now,
    required this.times,
    required this.active,
    required this.olive,
  });

  final DateTime now;
  final DailyPrayerTimes? times;
  final PrayerPeriod? active;
  final Color olive;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final summaryPeriod = active ?? PrayerPeriod.dhuhr;
    final summaryStart = times == null
        ? '--:--'
        : formatPrayerTime(prayerStart(summaryPeriod, times!));
    final summaryEnd = times == null
        ? '--:--'
        : formatPrayerTime(prayerEnd(summaryPeriod, times!));
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: olive),
        Positioned(
          top: 110.h,
          left: 70.w,
          right: 70.w,
          height: 120.h,
          child: Image.asset('assets/images/backImg2.png', fit: BoxFit.fill),
        ),
        Positioned(
          top: 9.h,
          left: 14.w,
          child: IconButton(
            tooltip: appText.back,
            onPressed: () => Navigator.of(context).pop(),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF7F5CE),
              foregroundColor: const Color(0xFF526044),
            ),
            icon: const Icon(Icons.chevron_left),
          ),
        ),
        Positioned(
          top: 9.h,
          right: 14.w,
          child: IconButton(
            tooltip: appText.setAllAlarm,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SetAllAlarmScreen(times: times),
              ),
            ),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF7F5CE),
              foregroundColor: const Color(0xFF526044),
            ),
            icon: const Icon(Icons.alarm_add_outlined),
          ),
        ),
        Positioned(
          top: 18.h,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Text(
              appText.prayerTimesTitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 15.sp),
            ),
          ),
        ),
        Positioned(
          top: 65.h,
          left: 30.w,
          right: 30.w,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    times?.hijriDate ?? appText.hijriDateUnavailable,
                    style: _italicStyle(10.sp),
                  ),
                ),
              ),
              SizedBox(width: 24.w),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    times?.readableDate ?? _fallbackDate(now),
                    style: _italicStyle(10.sp),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 90.h,
          left: 33.w,
          right: 33.w,
          child: SizedBox(
            height: 142.h,
            child: const CustomPaint(painter: PrayerArcPainter()),
          ),
        ),
        Positioned(
          top: 102.h,
          right: 48.w,
          child: SizedBox.square(
            dimension: 43.r,
            child: const CustomPaint(painter: PrayerSunPainter()),
          ),
        ),
        Positioned(
          top: 121.h,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Text(
                times?.readableDate ?? _fallbackDate(now),
                style: TextStyle(color: Colors.white70, fontSize: 10.sp),
              ),
              Text(
                _formatCurrentTime(now),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                appText.locationPlaceholder,
                style: TextStyle(color: Colors.white70, fontSize: 9.sp),
              ),
            ],
          ),
        ),
        Positioned(
          top: 189.h,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: const Color(0xFFE8EFB8),
                borderRadius: BorderRadius.circular(17.r),
                border: Border.all(color: const Color(0xFFA7B55E)),
              ),
              child: Column(
                children: [
                  Text(
                    active == null
                        ? '${appText.nextPrefix} ${summaryPeriod.displayName(appText)}'
                        : '${summaryPeriod.displayName(appText)} ${appText.prayerTimeSuffix}',
                    style: TextStyle(fontSize: 11.sp),
                  ),
                  Text(
                    '$summaryStart – $summaryEnd',
                    style: TextStyle(fontSize: 10.sp),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 61.w,
          right: 61.w,
          bottom: 12.h,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _EdgeLabel(
                  title: '${appText.sunrise}, ${appText.trishal}',
                  value: times == null
                      ? '--:--'
                      : formatPrayerTime(times!.sunrise),
                ),
              ),
              SizedBox(width: 20.w),
              Expanded(
                child: _EdgeLabel(
                  title: '${appText.sunset}, ${appText.trishal}',
                  value: times == null
                      ? '--:--'
                      : formatPrayerTime(times!.sunset),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static TextStyle _italicStyle(double size) => TextStyle(
    color: Colors.white,
    fontSize: size,
    fontFamily: 'Times New Roman',
    fontStyle: FontStyle.italic,
  );

  static String _fallbackDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-${date.year}';

  static String _formatCurrentTime(DateTime date) =>
      formatPrayerTime(PrayerClockTime(hour: date.hour, minute: date.minute));
}

class _EdgeLabel extends StatelessWidget {
  const _EdgeLabel({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        title,
        style: TextStyle(color: Colors.white, fontSize: 9.sp),
      ),
      SizedBox(height: 4.h),
      Text(
        value,
        style: TextStyle(color: Colors.white, fontSize: 11.sp),
      ),
    ],
  );
}

class _PrayerList extends StatelessWidget {
  const _PrayerList({required this.times, required this.active});

  final DailyPrayerTimes? times;
  final PrayerPeriod? active;

  @override
  Widget build(BuildContext context) {
    final rows = PrayerPeriod.values;
    return Column(
      children: [
        for (var index = 0; index < rows.length; index++) ...[
          Expanded(
            child: _PrayerRow(
              period: rows[index],
              times: times,
              active: active == rows[index],
            ),
          ),
          if (index != rows.length - 1) SizedBox(height: 9.h),
        ],
      ],
    );
  }
}

class _PrayerRow extends StatelessWidget {
  const _PrayerRow({
    required this.period,
    required this.times,
    required this.active,
  });

  final PrayerPeriod period;
  final DailyPrayerTimes? times;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    final start = times == null
        ? '--:--'
        : formatPrayerTime(prayerStart(period, times!));
    final end = times == null
        ? '--:--'
        : formatPrayerTime(prayerEnd(period, times!));
    return Row(
      children: [
        Container(
          width: 20.r,
          height: 20.r,
          decoration: BoxDecoration(
            color: active ? const Color(0xFF829061) : const Color(0xFFDDEBB5),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: 10.r,
              height: 10.r,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        SizedBox(width: 13.w),
        Expanded(
          child: Container(
            key: active ? const ValueKey('active-prayer-row') : null,
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: active
                    ? const Color(0xFF7F8E60)
                    : const Color(0xFFDCE9B8),
                width: active ? 2 : 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x10000000),
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 38.r,
                  height: 38.r,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8D7),
                    borderRadius: BorderRadius.circular(9.r),
                  ),
                  child: Icon(_icon, color: _iconColor, size: 23.sp),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        period.displayName(appText),
                        style: TextStyle(fontSize: 12.sp),
                      ),
                      SizedBox(height: 3.h),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '$start – $end',
                          style: TextStyle(fontSize: 8.sp),
                        ),
                      ),
                    ],
                  ),
                ),
                Tooltip(
                  message:
                      '${appText.setAlarmFor} ${period.displayName(appText)}',
                  child: IconButton(
                    key: const ValueKey('alarm-control'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SetAlarmScreen(
                          period: period,
                          initialTime: times == null
                              ? null
                              : prayerStart(period, times!),
                        ),
                      ),
                    ),
                    icon: Icon(Icons.alarm, size: 19.sp),
                    color: const Color(0xFF7E8C61),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  IconData get _icon => switch (period) {
    PrayerPeriod.fajr => Icons.wb_twilight,
    PrayerPeriod.dhuhr => Icons.wb_sunny,
    PrayerPeriod.asr => Icons.sunny,
    PrayerPeriod.maghrib => Icons.wb_twilight_outlined,
    PrayerPeriod.isha => Icons.nights_stay,
  };

  Color get _iconColor => switch (period) {
    PrayerPeriod.fajr => const Color(0xFFFFC83D),
    PrayerPeriod.dhuhr => const Color(0xFFFFC83D),
    PrayerPeriod.asr => const Color(0xFFFFAA2C),
    PrayerPeriod.maghrib => const Color(0xFFFF8E4A),
    PrayerPeriod.isha => const Color(0xFFEACB2B),
  };
}
