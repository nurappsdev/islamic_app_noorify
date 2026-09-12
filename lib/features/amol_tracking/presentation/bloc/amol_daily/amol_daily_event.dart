abstract class AmolDailyEvent {
  const AmolDailyEvent();
}

/// Loads `GET /amol/tracker/daily?date=[date]` (`YYYY-MM-DD`, the device's
/// today by default — see the screen that dispatches this).
class LoadAmolDaily extends AmolDailyEvent {
  const LoadAmolDaily(this.date);

  final String date;
}
