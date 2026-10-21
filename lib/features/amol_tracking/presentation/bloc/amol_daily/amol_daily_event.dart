abstract class AmolDailyEvent {
  const AmolDailyEvent();
}

/// Loads `GET /amol/tracker/daily?date=[date]` (`YYYY-MM-DD`, selected by the
/// frontend's location-aware Fajr-to-Fajr tracking cycle).
class LoadAmolDaily extends AmolDailyEvent {
  const LoadAmolDaily(this.date, {this.silent = false});

  final String date;

  /// A background refresh of a checklist that is already on screen: it does
  /// not switch the screen to its loading state (no flash of placeholders),
  /// and a failure leaves what is showing as it is.
  final bool silent;
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
