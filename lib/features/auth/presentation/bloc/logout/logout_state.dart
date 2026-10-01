enum LogoutStatus { initial, inProgress, done }

class LogoutState {
  const LogoutState(this.status);

  const LogoutState.initial() : status = LogoutStatus.initial;

  final LogoutStatus status;

  bool get inProgress => status == LogoutStatus.inProgress;
  bool get isDone => status == LogoutStatus.done;
}
