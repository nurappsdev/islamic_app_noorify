abstract class AmolDailyEvent {
  const AmolDailyEvent();
}

/// Loads `GET /amol/tracker/daily?date=[date]` (`YYYY-MM-DD`, the device's
/// today by default — see the screen that dispatches this).
class LoadAmolDaily extends AmolDailyEvent {
  const LoadAmolDaily(this.date);

  final String date;
}

/// Marks one checklist item done (`POST /amol/tracker/log-item`). The
/// screen only dispatches this after its own prayer-time gate passes.
class LogAmolDailyItem extends AmolDailyEvent {
  const LogAmolDailyItem({
    required this.logDate,
    required this.pillarKey,
    required this.itemKey,
  });

  final String logDate;
  final String pillarKey;
  final String itemKey;
}

/// Un-checks one checklist item (`DELETE /amol/tracker/delete-item`).
class UncheckAmolDailyItem extends AmolDailyEvent {
  const UncheckAmolDailyItem({
    required this.logDate,
    required this.pillarKey,
    required this.itemKey,
  });

  final String logDate;
  final String pillarKey;
  final String itemKey;
}
