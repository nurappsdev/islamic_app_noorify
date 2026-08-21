import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/features/home/domain/current_prayer.dart';
import 'package:islami_app_noorify/features/home/domain/daily_prayer_times.dart';
import 'package:islami_app_noorify/features/alarm/presentation/screens/set_alarm_screen.dart';
import 'package:islami_app_noorify/features/alarm/presentation/widgets/alarm_settings_widgets.dart';

class SetAllAlarmScreen extends StatefulWidget {
  const SetAllAlarmScreen({super.key, this.times});

  final DailyPrayerTimes? times;

  @override
  State<SetAllAlarmScreen> createState() => _SetAllAlarmScreenState();
}

class _SetAllAlarmScreenState extends State<SetAllAlarmScreen> {
  static const _offsetOptions = [
    'At prayer time',
    'Before 5 Min',
    'Before 10 Min',
    'Before 15 Min',
    'Before 20 Min',
    'Before 30 Min',
    'Before 40 Min',
    'Before 60 Min',
  ];

  String _offset = 'Before 40 Min';
  bool _vibrate = false;
  bool _ring = true;
  bool _vibrateAndRing = false;

  Future<void> _pickOffset() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFFFCFDF8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final option in _offsetOptions)
              ListTile(
                title: Text(option, style: alarmItalicStyle(14.sp)),
                trailing: option == _offset
                    ? const Icon(Icons.check, color: Color(0xFF8D9B70))
                    : null,
                onTap: () => Navigator.of(context).pop(option),
              ),
          ],
        ),
      ),
    );
    if (selected != null) setState(() => _offset = selected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFDF8),
      body: SafeArea(
        child: Column(
          children: [
            const AlarmBackHeader(title: 'Set All Alarm'),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 24.h),
                children: [
                  Text('Set Alarm Before Prayer', style: alarmItalicStyle(14.sp)),
                  SizedBox(height: 10.h),
                  InkWell(
                    onTap: _pickOffset,
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
                          Text(_offset, style: alarmItalicStyle(14.sp)),
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
                    label: 'Vibrate',
                    value: _vibrate,
                    onChanged: (v) => setState(() => _vibrate = v),
                  ),
                  SizedBox(height: 18.h),
                  AlarmToggleRow(
                    label: 'Ring',
                    value: _ring,
                    onChanged: (v) => setState(() => _ring = v),
                  ),
                  SizedBox(height: 22.h),
                  Text('Set Ringtone', style: alarmItalicStyle(14.sp)),
                  SizedBox(height: 10.h),
                  const RingtoneSearchField(),
                  SizedBox(height: 22.h),
                  AlarmToggleRow(
                    label: 'Vibrate and ring',
                    value: _vibrateAndRing,
                    onChanged: (v) => setState(() => _vibrateAndRing = v),
                  ),
                  SizedBox(height: 26.h),
                  for (final period in PrayerPeriod.values) ...[
                    _AllAlarmRow(period: period, times: widget.times),
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
                        period.displayName,
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
                          style: TextStyle(fontSize: 9.sp, color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                ),
                Tooltip(
                  message: 'Set alarm for ${period.displayName}',
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
