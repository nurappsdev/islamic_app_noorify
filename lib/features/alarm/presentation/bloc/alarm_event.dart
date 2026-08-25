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

class SelectOffset extends AlarmEvent {
  const SelectOffset(this.index);

  final int index;
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
