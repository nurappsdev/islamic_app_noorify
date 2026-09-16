import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/home/domain/current_prayer.dart';
import 'package:islami_app_noorify/features/home/domain/daily_prayer_times.dart';
import 'package:islami_app_noorify/features/alarm/presentation/screens/set_alarm_screen.dart';
import 'package:islami_app_noorify/features/alarm/presentation/bloc/alarm_bloc.dart';
import 'package:islami_app_noorify/features/alarm/presentation/widgets/alarm_settings_widgets.dart';

/// The 3 fixed presets shown in the "Set Alarm Before Prayer" dropdown
/// (a 4th, always-last "Custom" entry opens [_CustomOffsetDialog] instead).
const _offsetPresets = [40, 30, 20];

/// Sentinel returned by the dropdown when "Custom" is tapped.
const _customOffsetSentinel = -1;

String _offsetLabel(int minutes, AppText appText) => switch (minutes) {
  40 => appText.offsetBefore40Min,
  30 => appText.offsetBefore30Min,
  20 => appText.offsetBefore20Min,
  _ => '${appText.offsetCustom} ($minutes ${appText.offsetMinutesUnit})',
};

class SetAllAlarmScreen extends StatelessWidget {
  const SetAllAlarmScreen({super.key, this.times});

  final DailyPrayerTimes? times;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AlarmBloc(),
      child: _SetAllAlarmView(times: times),
    );
  }
}

class _SetAllAlarmView extends StatefulWidget {
  const _SetAllAlarmView({this.times});

  final DailyPrayerTimes? times;

  @override
  State<_SetAllAlarmView> createState() => _SetAllAlarmViewState();
}

class _SetAllAlarmViewState extends State<_SetAllAlarmView> {
  final _offsetFieldKey = GlobalKey();

  /// Opens a compact dropdown anchored under the "Set Alarm Before Prayer"
  /// field (img_23): the 3 presets plus "Custom", which instead opens
  /// [_CustomOffsetDialog] for picking any 1-59 value.
  Future<void> _pickOffset(BuildContext context) async {
    final appText = AppText.readOf(context);
    final renderBox =
        _offsetFieldKey.currentContext!.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final topLeft = renderBox.localToGlobal(
      Offset(0, renderBox.size.height + 6.h),
      ancestor: overlay,
    );
    final position = RelativeRect.fromRect(
      topLeft & Size(renderBox.size.width, 0),
      Offset.zero & overlay.size,
    );

    final selected = await showMenu<int>(
      context: context,
      position: position,
      color: const Color(0xFFFCFDF8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14.r),
        side: const BorderSide(color: Color(0xFFDCE9B8)),
      ),
      constraints: BoxConstraints(minWidth: renderBox.size.width),
      items: [
        for (final minutes in _offsetPresets) ...[
          PopupMenuItem<int>(
            value: minutes,
            child: Text(
              _offsetLabel(minutes, appText),
              style: alarmItalicStyle(14.sp),
            ),
          ),
          const PopupMenuDivider(height: 1),
        ],
        PopupMenuItem<int>(
          value: _customOffsetSentinel,
          child: Text(appText.offsetCustom, style: alarmItalicStyle(14.sp)),
        ),
      ],
    );
    if (selected == null || !context.mounted) return;
    if (selected == _customOffsetSentinel) {
      final currentMinutes = context.read<AlarmBloc>().state.offsetMinutes;
      final custom = await showDialog<int>(
        context: context,
        builder: (_) => _CustomOffsetDialog(initialMinutes: currentMinutes),
      );
      if (custom != null && context.mounted) {
        context.read<AlarmBloc>().add(SelectOffset(custom));
      }
    } else {
      context.read<AlarmBloc>().add(SelectOffset(selected));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AlarmBloc>().state;
    final bloc = context.read<AlarmBloc>();
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
                      key: _offsetFieldKey,
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
                            _offsetLabel(state.offsetMinutes, appText),
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
                    onChanged: (value) => bloc.add(SetVibrate(value)),
                  ),
                  SizedBox(height: 18.h),
                  AlarmToggleRow(
                    label: appText.ring,
                    value: state.ring,
                    onChanged: (value) => bloc.add(SetRing(value)),
                  ),
                  SizedBox(height: 22.h),
                  Text(appText.setRingtone, style: alarmItalicStyle(14.sp)),
                  SizedBox(height: 10.h),
                  const RingtoneSearchField(),
                  SizedBox(height: 22.h),
                  AlarmToggleRow(
                    label: appText.vibrateAndRing,
                    value: state.vibrateAndRing,
                    onChanged: (value) => bloc.add(SetVibrateAndRing(value)),
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

/// The "Custom" minutes picker (img_24) — free-form 1-59 entry, opened when
/// "Custom" is picked from the offset dropdown.
class _CustomOffsetDialog extends StatefulWidget {
  const _CustomOffsetDialog({required this.initialMinutes});

  final int initialMinutes;

  @override
  State<_CustomOffsetDialog> createState() => _CustomOffsetDialogState();
}

class _CustomOffsetDialogState extends State<_CustomOffsetDialog> {
  late final _controller = TextEditingController(
    text: widget.initialMinutes.toString(),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final parsed = int.tryParse(_controller.text) ?? widget.initialMinutes;
    Navigator.of(context).pop(parsed.clamp(1, 59));
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              appText.setAlarmBeforePrayer,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFFF15A24),
                fontSize: 19.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 22.h),
            Container(
              height: 50.h,
              padding: EdgeInsets.symmetric(horizontal: 18.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25.r),
                border: Border.all(color: const Color(0xFFDCE9B8)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                      onSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      style: TextStyle(fontSize: 15.sp, color: Colors.black87),
                    ),
                  ),
                  Text(
                    appText.offsetMinutesUnit,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: const Color(0xFF7E8C61),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 22.h),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46.h,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFBDCDC),
                        foregroundColor: const Color(0xFFD84A4A),
                        elevation: 0,
                        shape: const StadiumBorder(),
                      ),
                      child: Text(
                        appText.alarmCancel,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: SizedBox(
                    height: 46.h,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8D9B70),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: const StadiumBorder(),
                      ),
                      child: Text(
                        appText.alarmSet,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
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
