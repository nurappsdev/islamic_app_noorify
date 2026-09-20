import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/alarm/domain/entities/alarm_entry.dart';
import 'package:islami_app_noorify/features/alarm/domain/entities/ringtone.dart';
import 'package:islami_app_noorify/features/home/domain/current_prayer.dart';
import 'package:islami_app_noorify/features/home/domain/prayer_theme_schedule.dart';
import 'package:islami_app_noorify/features/alarm/presentation/bloc/alarm_bloc.dart';
import 'package:islami_app_noorify/features/alarm/presentation/widgets/alarm_settings_widgets.dart';

class SetAlarmScreen extends StatelessWidget {
  const SetAlarmScreen({
    super.key,
    this.period,
    this.initialTime,
    this.onSetAlarm,
  });

  final PrayerPeriod? period;
  final PrayerClockTime? initialTime;

  /// When provided, this screen behaves as a "create a new alarm" flow: a
  /// "Set Alarm" button appears at the bottom once the user turns on any of
  /// the Vibrate/Ring toggles, and tapping it builds an [AlarmEntry] from
  /// the current wheel/toggle selection, hands it to this callback, then
  /// pops. When `null` (the existing per-prayer alarm flow), the screen is
  /// unchanged — no button is shown.
  final ValueChanged<AlarmEntry>? onSetAlarm;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AlarmBloc(initialTime: initialTime),
      child: _SetAlarmView(period: period, onSetAlarm: onSetAlarm),
    );
  }
}

const _olive = Color(0xFF8D9B70);
const _fadedNear = Color(0xFFBFC79B);
const _fadedFar = Color(0xFFE3E6D3);
const _hours = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
const _periods = ['AM', 'PM'];

class _SetAlarmView extends StatefulWidget {
  const _SetAlarmView({required this.period, this.onSetAlarm});

  final PrayerPeriod? period;
  final ValueChanged<AlarmEntry>? onSetAlarm;

  @override
  State<_SetAlarmView> createState() => _SetAlarmViewState();
}

class _SetAlarmViewState extends State<_SetAlarmView> {
  late final FixedExtentScrollController _hourController;
  late final FixedExtentScrollController _minuteController;
  late final FixedExtentScrollController _periodController;
  final _labelController = TextEditingController();
  Ringtone? _selectedRingtone;

  @override
  void initState() {
    super.initState();
    final state = context.read<AlarmBloc>().state;
    _hourController = FixedExtentScrollController(initialItem: state.hourIndex);
    _minuteController = FixedExtentScrollController(
      initialItem: state.minuteIndex,
    );
    _periodController = FixedExtentScrollController(
      initialItem: state.periodIndex,
    );
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _periodController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AlarmBloc>().state;
    final bloc = context.read<AlarmBloc>();
    final appText = AppText.of(context);
    final showSetAlarmButton =
        widget.onSetAlarm != null &&
        (state.vibrateAndRing || state.vibrate || state.ring);
    return Scaffold(
      backgroundColor: context.pageColor(Color(0xFFFCFDF8)),
      body: SafeArea(
        child: Column(
          children: [
            AlarmBackHeader(
              title: appText.setAlarm,
              subtitle: widget.period?.displayName(appText),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20.h),
                    Center(
                      child: _TimeWheel(
                        hourController: _hourController,
                        minuteController: _minuteController,
                        periodController: _periodController,
                        hourIndex: state.hourIndex,
                        minuteIndex: state.minuteIndex,
                        periodIndex: state.periodIndex,
                        onHourChanged: (index) => bloc.add(SelectHour(index)),
                        onMinuteChanged: (index) =>
                            bloc.add(SelectMinute(index)),
                        onPeriodChanged: (index) =>
                            bloc.add(SelectPeriod(index)),
                      ),
                    ),
                    SizedBox(height: 26.h),
                    if (widget.onSetAlarm != null) ...[
                      Text(
                        appText.alarmLabel,
                        style: alarmItalicStyle(14.sp, context: context),
                      ),
                      SizedBox(height: 10.h),
                      Container(
                        height: 44.h,
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22.r),
                          border: Border.all(
                            color: context.lineColor(Color(0xFFDCE9B8)),
                          ),
                        ),
                        child: Center(
                          child: TextField(
                            controller: _labelController,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              hintText: appText.alarmLabelHint,
                              hintStyle: alarmItalicStyle(
                                13.sp,
                                color: const Color(0xFF9AA687),
                                context: context,
                              ),
                            ),
                            style: alarmItalicStyle(13.sp, context: context),
                          ),
                        ),
                      ),
                      SizedBox(height: 22.h),
                    ],
                    AlarmToggleRow(
                      label: appText.vibrateAndRing,
                      value: state.vibrateAndRing,
                      onChanged: (value) => bloc.add(SetVibrateAndRing(value)),
                    ),
                    SizedBox(height: 22.h),
                    Text(
                      appText.setRingtone,
                      style: alarmItalicStyle(14.sp, context: context),
                    ),
                    SizedBox(height: 10.h),
                    RingtoneSearchField(
                      onSelected: (ringtone) =>
                          setState(() => _selectedRingtone = ringtone),
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
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),
            if (showSetAlarmButton)
              Padding(
                padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 20.h),
                child: SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onSetAlarm!(_buildEntry(state));
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.surfaceColor(_olive),
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      appText.setAlarm,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Converts the wheel's 12-hour `hourIndex`/`periodIndex` selection (plus
  /// `minuteIndex`, already 0-59) into a 24-hour [AlarmEntry].
  AlarmEntry _buildEntry(AlarmState state) {
    final hour12 = _hours[state.hourIndex];
    final isPm = state.periodIndex == 1;
    final hour24 = hour12 % 12 + (isPm ? 12 : 0);
    return AlarmEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      hour: hour24,
      minute: state.minuteIndex,
      vibrateAndRing: state.vibrateAndRing,
      vibrate: state.vibrate,
      ring: state.ring,
      enabled: true,
      label: _labelController.text.trim(),
      ringtoneId: _selectedRingtone?.id ?? AlarmEntry.defaultRingtoneId,
      ringtoneName: _selectedRingtone?.name ?? AlarmEntry.defaultRingtoneName,
      ringtoneUrl: _selectedRingtone?.audioUrl ?? '',
    );
  }
}

class _TimeWheel extends StatelessWidget {
  const _TimeWheel({
    required this.hourController,
    required this.minuteController,
    required this.periodController,
    required this.hourIndex,
    required this.minuteIndex,
    required this.periodIndex,
    required this.onHourChanged,
    required this.onMinuteChanged,
    required this.onPeriodChanged,
  });

  final FixedExtentScrollController hourController;
  final FixedExtentScrollController minuteController;
  final FixedExtentScrollController periodController;
  final int hourIndex;
  final int minuteIndex;
  final int periodIndex;
  final ValueChanged<int> onHourChanged;
  final ValueChanged<int> onMinuteChanged;
  final ValueChanged<int> onPeriodChanged;

  static const _itemExtent = 40.0;

  @override
  Widget build(BuildContext context) {
    final itemExtent = _itemExtent.h;
    return SizedBox(
      height: itemExtent * 5.6,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Positioned(
          //   top: itemExtent * 1.6,
          //   child: Container(
          //     width: 40.w,
          //     height: 3.h,
          //     decoration: BoxDecoration(
          //       color: const Color(0xFF6EA8DE),
          //       borderRadius: BorderRadius.circular(2.r),
          //     ),
          //   ),
          // ),
          IgnorePointer(
            child: Center(
              child: Container(
                height: itemExtent,
                margin: EdgeInsets.symmetric(horizontal: 46.w),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: context.lineColor(Color(0xFFD8C879)),
                  ),
                  borderRadius: BorderRadius.circular(30.r),
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 60.w,
                child: _Wheel(
                  controller: hourController,
                  itemExtent: itemExtent,
                  itemCount: _hours.length,
                  selectedIndex: hourIndex,
                  label: (i) => _hours[i].toString().padLeft(2, '0'),
                  onChanged: onHourChanged,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Text(
                  ':',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w700,
                    color: context.inkColor(Colors.black87),
                  ),
                ),
              ),
              SizedBox(
                width: 60.w,
                child: _Wheel(
                  controller: minuteController,
                  itemExtent: itemExtent,
                  itemCount: 60,
                  selectedIndex: minuteIndex,
                  label: (i) => i.toString().padLeft(2, '0'),
                  onChanged: onMinuteChanged,
                ),
              ),
              SizedBox(width: 10.w),
              SizedBox(
                width: 50.w,
                child: _Wheel(
                  controller: periodController,
                  itemExtent: itemExtent,
                  itemCount: _periods.length,
                  selectedIndex: periodIndex,
                  label: (i) => _periods[i],
                  onChanged: onPeriodChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Wheel extends StatelessWidget {
  const _Wheel({
    required this.controller,
    required this.itemExtent,
    required this.itemCount,
    required this.selectedIndex,
    required this.label,
    required this.onChanged,
  });

  final FixedExtentScrollController controller;
  final double itemExtent;
  final int itemCount;
  final int selectedIndex;
  final String Function(int index) label;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: itemExtent,
      diameterRatio: 1.9,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: onChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: itemCount,
        builder: (context, index) {
          final distance = (index - selectedIndex).abs();
          final isSelected = distance == 0;
          return Center(
            child: Text(
              label(index),
              style: TextStyle(
                fontSize: isSelected ? 26.sp : (distance == 1 ? 18.sp : 14.sp),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: context.inkColor(
                  isSelected
                      ? _olive
                      : distance == 1
                      ? _fadedNear
                      : _fadedFar,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
