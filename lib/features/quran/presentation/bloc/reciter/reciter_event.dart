abstract class ReciterEvent {
  const ReciterEvent();
}

class LoadReciters extends ReciterEvent {
  const LoadReciters();
}

class SelectReciter extends ReciterEvent {
  const SelectReciter(this.recitationId);

  final int recitationId;
}
