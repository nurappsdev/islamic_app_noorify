import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/features/home/domain/current_prayer.dart';
import 'package:islami_app_noorify/features/home/domain/prayer_theme_schedule.dart';
import 'package:islami_app_noorify/features/alarm/presentation/widgets/alarm_settings_widgets.dart';

class SetAlarmScreen extends StatefulWidget {
  const SetAlarmScreen({super.key, required this.period, this.initialTime});

  final PrayerPeriod period;
  final PrayerClockTime? initialTime;

  @override
  State<SetAlarmScreen> createState() => _SetAlarmScreenState();
}

const _olive = Color(0xFF8D9B70);
const _fadedNear = Color(0xFFBFC79B);
const _fadedFar = Color(0xFFE3E6D3);
const _hours = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
const _periods = ['AM', 'PM'];

class _SetAlarmScreenState extends State<SetAlarmScreen> {
  late final FixedExtentScrollController _hourController;
  late final FixedExtentScrollController _minuteController;
  late final FixedExtentScrollController _periodController;

  late int _hourIndex;
  late int _minuteIndex;
  late int _periodIndex;

  bool _vibrateAndRing = true;
  bool _vibrate = false;
  bool _ring = false;

  @override
  void initState() {
    super.initState();
    final time = widget.initialTime ?? const PrayerClockTime(hour: 10, minute: 0);
    final isPm = time.hour >= 12;
    final hour12 = time.hour % 12 == 0 ? 12 : time.hour % 12;
    _hourIndex = hour12 - 1;
    _minuteIndex = time.minute;
    _periodIndex = isPm ? 1 : 0;
    _hourController = FixedExtentScrollController(initialItem: _hourIndex);
    _minuteController = FixedExtentScrollController(initialItem: _minuteIndex);
    _periodController = FixedExtentScrollController(initialItem: _periodIndex);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _periodController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFDF8),
      body: SafeArea(
        child: Column(
          children: [
            AlarmBackHeader(title: 'Set Alarm', subtitle: widget.period.displayName),
            SizedBox(height: 20.h),
            _TimeWheel(
              hourController: _hourController,
              minuteController: _minuteController,
              periodController: _periodController,
              hourIndex: _hourIndex,
              minuteIndex: _minuteIndex,
              periodIndex: _periodIndex,
              onHourChanged: (i) => setState(() => _hourIndex = i),
              onMinuteChanged: (i) => setState(() => _minuteIndex = i),
              onPeriodChanged: (i) => setState(() => _periodIndex = i),
            ),
            SizedBox(height: 26.h),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AlarmToggleRow(
                      label: 'Vibrate and ring',
                      value: _vibrateAndRing,
                      onChanged: (v) => setState(() => _vibrateAndRing = v),
                    ),
                    SizedBox(height: 22.h),
                    Text('Set Ringtone', style: alarmItalicStyle(14.sp)),
                    SizedBox(height: 10.h),
                    const RingtoneSearchField(),
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
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
                  border: Border.all(color: const Color(0xFFD8C879)),
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
                    color: Colors.black87,
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
                color: isSelected
                    ? _olive
                    : distance == 1
                        ? _fadedNear
                        : _fadedFar,
              ),
            ),
          );
        },
      ),
    );
  }
}

