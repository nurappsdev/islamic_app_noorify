import 'package:islami_app_noorify/features/home/domain/prayer_theme_schedule.dart';

class AlarmState {
  const AlarmState({
    this.hourIndex = 9,
    this.minuteIndex = 0,
    this.periodIndex = 0,
    this.offset = 'Before 40 Min',
    this.vibrateAndRing = true,
    this.vibrate = false,
    this.ring = false,
  });

  final int hourIndex;
  final int minuteIndex;
  final int periodIndex;
  final String offset;
  final bool vibrateAndRing;
  final bool vibrate;
  final bool ring;

  factory AlarmState.fromTime(PrayerClockTime time) {
    final isPm = time.hour >= 12;
    final hour12 = time.hour % 12 == 0 ? 12 : time.hour % 12;
    return AlarmState(
      hourIndex: hour12 - 1,
      minuteIndex: time.minute,
      periodIndex: isPm ? 1 : 0,
    );
  }

  AlarmState copyWith({
    int? hourIndex,
    int? minuteIndex,
    int? periodIndex,
    String? offset,
    bool? vibrateAndRing,
    bool? vibrate,
    bool? ring,
  }) {
    return AlarmState(
      hourIndex: hourIndex ?? this.hourIndex,
      minuteIndex: minuteIndex ?? this.minuteIndex,
      periodIndex: periodIndex ?? this.periodIndex,
      offset: offset ?? this.offset,
      vibrateAndRing: vibrateAndRing ?? this.vibrateAndRing,
      vibrate: vibrate ?? this.vibrate,
      ring: ring ?? this.ring,
    );
  }
}
