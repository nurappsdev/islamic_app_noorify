abstract class PrayerTimesEvent {
  const PrayerTimesEvent();
}

class LoadPrayerTimes extends PrayerTimesEvent {
  const LoadPrayerTimes();
}

class StartClock extends PrayerTimesEvent {
  const StartClock();
}
