import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/theme/app_palette.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/home/domain/calendar/date_labels.dart';
import 'package:tuhfatul_muslim/features/home/data/services/prayer_time_service.dart';
import 'package:tuhfatul_muslim/features/home/domain/daily_prayer_times.dart';
import 'package:tuhfatul_muslim/features/home/presentation/screens/home_screen.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

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
    final bangla =
        context.watch<LanguageBloc>().state.language == AppLanguage.bangla;
    final times = _times;
    final windows = times == null
        ? null
        : ProhibitedPrayerWindows.fromDailyTimes(times);
    return InkWell(
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => _ProhibitedTimesDialog(
          appText: appText,
          bangla: bangla,
          windows: windows,
        ),
      ),
      borderRadius: BorderRadius.circular(11.r),
      child: HomeCard(
        padding: EdgeInsets.fromLTRB(10.w, 10.h, 10.w, 10.h),
        backgroundColor: context.appPalette.dangerSurface,
        borderColor: context.lineColor(Color(0xFFFF4B4B)),
        child: Column(
          children: [
            Text(
              appText.prohibitedPrayerTimes,
              style: homeSansStyle(context: context, fontSize: 14.sp),
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                _ForbiddenTime(
                  title: appText.sunrise,
                  value: localizeClockText(
                    windows?.sunrise.formatted ?? '--:-- – --:--',
                    bangla: bangla,
                  ),
                ),
                _ForbiddenTime(
                  title: appText.jawaal,
                  value: localizeClockText(
                    windows?.zawal.formatted ?? '--:-- – --:--',
                    bangla: bangla,
                  ),
                ),
                _ForbiddenTime(
                  title: appText.sunset,
                  value: localizeClockText(
                    windows?.sunset.formatted ?? '--:-- – --:--',
                    bangla: bangla,
                  ),
                ),
              ],
            ),
          ],
        ),
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
          color: context.appPalette.dangerTint,
          borderRadius: BorderRadius.circular(7.r),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: homeSansStyle(context: context, fontSize: 10.sp),
            ),
            SizedBox(height: 7.h),
            FittedBox(
              child: Text(
                value,
                style: homeSansStyle(
                  context: context,
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

/// Enlarged, centered detail view for [ProhibitedPrayerTimesCard] — the same
/// [windows] the card already computed from [DailyPrayerTimes], just laid
/// out bigger and clearer. No prayer-time logic is recalculated here.
class _ProhibitedTimesDialog extends StatelessWidget {
  const _ProhibitedTimesDialog({
    required this.appText,
    required this.bangla,
    required this.windows,
  });

  final AppText appText;
  final bool bangla;
  final ProhibitedPrayerWindows? windows;

  String _rangeFor(ProhibitedPrayerWindow? window) =>
      localizeClockText(window?.formatted ?? '--:-- – --:--', bangla: bangla);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 420.w),
        child: Container(
          padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 20.h),
          decoration: BoxDecoration(
            color: context.appPalette.dangerSurface,
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(color: context.lineColor(Color(0xFFFF4B4B))),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 24.r,
                offset: Offset(0, 10.h),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        appText.prohibitedPrayerTimes,
                        style: homeSansStyle(
                          context: context,
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(20.r),
                      child: Padding(
                        padding: EdgeInsets.all(4.r),
                        child: Icon(
                          Icons.close_rounded,
                          size: 22.sp,
                          color: context.inkColor(Color(0xFF8A2E2E)),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                _ProhibitedTimeRow(
                  icon: Icons.wb_sunny_outlined,
                  title: appText.sunrise,
                  value: _rangeFor(windows?.sunrise),
                ),
                SizedBox(height: 12.h),
                _ProhibitedTimeRow(
                  icon: Icons.brightness_7,
                  title: appText.jawaal,
                  value: _rangeFor(windows?.zawal),
                ),
                SizedBox(height: 12.h),
                _ProhibitedTimeRow(
                  icon: Icons.wb_twilight,
                  title: appText.sunset,
                  value: _rangeFor(windows?.sunset),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProhibitedTimeRow extends StatelessWidget {
  const _ProhibitedTimeRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: context.appPalette.dangerTint,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Container(
            width: 42.r,
            height: 42.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.surfaceColor(Colors.white),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 22.sp,
              color: context.inkColor(Color(0xFFCC3B3B)),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              title,
              style: homeSansStyle(
                context: context,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                value,
                style: homeSansStyle(
                  context: context,
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
