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
