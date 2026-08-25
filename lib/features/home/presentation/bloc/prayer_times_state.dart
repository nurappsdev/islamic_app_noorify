import 'package:islami_app_noorify/features/home/domain/daily_prayer_times.dart';

class PrayerTimesState {
  const PrayerTimesState({
    required this.now,
    this.times,
    this.isLoading = true,
  });

  final DateTime now;
  final DailyPrayerTimes? times;
  final bool isLoading;

  PrayerTimesState copyWith({
    DateTime? now,
    DailyPrayerTimes? times,
    bool? isLoading,
  }) {
    return PrayerTimesState(
      now: now ?? this.now,
      times: times ?? this.times,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
