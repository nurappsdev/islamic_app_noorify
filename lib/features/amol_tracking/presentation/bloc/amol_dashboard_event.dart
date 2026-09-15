abstract class AmolDashboardEvent {
  const AmolDashboardEvent();
}

class SelectPeriod extends AmolDashboardEvent {
  const SelectPeriod(this.period);

  final int period;
}

class ShiftDate extends AmolDashboardEvent {
  const ShiftDate(this.step, this.direction);

  final Duration step;
  final int direction;
}

/// Jumps the monthly tab straight to one calendar month (e.g. picked from a
/// "last 12 months" dropdown), instead of stepping 30 days at a time via
/// [ShiftDate]. Only [month]'s year/month are used.
class SelectMonth extends AmolDashboardEvent {
  const SelectMonth(this.month);

  final DateTime month;
}

/// Fetches `GET /amol/analytics/graph` for the current period/date. Fired
/// once when the bloc is created; [SelectPeriod] and [ShiftDate] each
/// trigger it again internally.
class LoadGraph extends AmolDashboardEvent {
  const LoadGraph();
}
