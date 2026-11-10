abstract class AlarmEvent {
  const AlarmEvent();
}

class SelectHour extends AlarmEvent {
  const SelectHour(this.index);

  final int index;
}

class SelectMinute extends AlarmEvent {
  const SelectMinute(this.index);

  final int index;
}

class SelectPeriod extends AlarmEvent {
  const SelectPeriod(this.index);

  final int index;
}

/// Sets the "before prayer" offset, in minutes — either a preset (20/30/40)
/// or a custom value (1-59) picked via the "Custom" dialog.
class SelectOffset extends AlarmEvent {
  const SelectOffset(this.minutes);

  final int minutes;
}

class SetVibrateAndRing extends AlarmEvent {
  const SetVibrateAndRing(this.value);

  final bool value;
}

class SetVibrate extends AlarmEvent {
  const SetVibrate(this.value);

  final bool value;
}

class SetRing extends AlarmEvent {
  const SetRing(this.value);

  final bool value;
}
