import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/home/domain/current_prayer.dart';
import 'package:islami_app_noorify/features/home/domain/daily_prayer_times.dart';
import 'package:islami_app_noorify/features/alarm/presentation/screens/set_alarm_screen.dart';
import 'package:islami_app_noorify/features/alarm/presentation/cubit/alarm_cubit.dart';
import 'package:islami_app_noorify/features/alarm/presentation/widgets/alarm_settings_widgets.dart';

class SetAllAlarmScreen extends StatelessWidget {
  const SetAllAlarmScreen({super.key, this.times});

  final DailyPrayerTimes? times;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AlarmCubit(),
      child: _SetAllAlarmView(times: times),
    );
  }
}

class _SetAllAlarmView extends StatelessWidget {
  const _SetAllAlarmView({this.times});

  final DailyPrayerTimes? times;

  Future<void> _pickOffset(BuildContext context) async {
    final appText = AppText.of(context);
    final offsetOptions = appText.alarmOffsetOptions;
    final selectedIndex = context.read<AlarmCubit>().state.offsetIndex;
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: const Color(0xFFFCFDF8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < offsetOptions.length; i++)
              ListTile(
                title: Text(offsetOptions[i], style: alarmItalicStyle(14.sp)),
                trailing: i == selectedIndex
                    ? const Icon(Icons.check, color: Color(0xFF8D9B70))
                    : null,
                onTap: () => Navigator.of(context).pop(i),
              ),
          ],
        ),
      ),
    );
    if (selected != null && context.mounted) {
      context.read<AlarmCubit>().selectOffset(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AlarmCubit>().state;
    final appText = AppText.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFCFDF8),
      body: SafeArea(
        child: Column(
          children: [
            AlarmBackHeader(title: appText.setAllAlarm),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 24.h),
                children: [
                  Text(
                    appText.setAlarmBeforePrayer,
                    style: alarmItalicStyle(14.sp),
                  ),
                  SizedBox(height: 10.h),
                  InkWell(
                    onTap: () => _pickOffset(context),
                    borderRadius: BorderRadius.circular(22.r),
                    child: Container(
                      height: 46.h,
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22.r),
                        border: Border.all(color: const Color(0xFFDCE9B8)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            appText.alarmOffsetOptions[state.offsetIndex],
                            style: alarmItalicStyle(14.sp),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: Color(0xFF9AA687),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 22.h),
                  AlarmToggleRow(
                    label: appText.vibrate,
                    value: state.vibrate,
                    onChanged: context.read<AlarmCubit>().setVibrate,
                  ),
                  SizedBox(height: 18.h),
                  AlarmToggleRow(
                    label: appText.ring,
                    value: state.ring,
                    onChanged: context.read<AlarmCubit>().setRing,
                  ),
                  SizedBox(height: 22.h),
                  Text(appText.setRingtone, style: alarmItalicStyle(14.sp)),
                  SizedBox(height: 10.h),
                  const RingtoneSearchField(),
                  SizedBox(height: 22.h),
                  AlarmToggleRow(
                    label: appText.vibrateAndRing,
                    value: state.vibrateAndRing,
                    onChanged: context.read<AlarmCubit>().setVibrateAndRing,
                  ),
                  SizedBox(height: 26.h),
                  for (final period in PrayerPeriod.values) ...[
                    _AllAlarmRow(period: period, times: times),
                    SizedBox(height: 14.h),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllAlarmRow extends StatelessWidget {
  const _AllAlarmRow({required this.period, required this.times});

  final PrayerPeriod period;
  final DailyPrayerTimes? times;

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
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF7F8E60), width: 1.6),
          ),
        ),
        SizedBox(width: 13.w),
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30.r),
              border: Border.all(color: const Color(0xFF7F8E60), width: 1.4),
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
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '$start – $end',
                          style: TextStyle(
                            fontSize: 9.sp,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Tooltip(
                  message:
                      '${appText.setAlarmFor} ${period.displayName(appText)}',
                  child: IconButton(
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
                    icon: Icon(Icons.access_alarm, size: 20.sp),
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
