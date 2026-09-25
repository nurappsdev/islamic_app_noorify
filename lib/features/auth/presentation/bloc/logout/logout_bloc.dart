import 'package:bloc/bloc.dart';

import 'package:islami_app_noorify/features/alarm/data/services/alarm_scheduler.dart';
import 'package:islami_app_noorify/features/auth/domain/usecases/logout_user.dart';

import 'logout_event.dart';
import 'logout_state.dart';

export 'logout_event.dart';
export 'logout_state.dart';

class LogoutBloc extends Bloc<LogoutEvent, LogoutState> {
  LogoutBloc(this._logoutUser) : super(const LogoutState.initial()) {
    on<LogoutRequested>(_onRequested);
  }

  final LogoutUser _logoutUser;

  Future<void> _onRequested(
    LogoutRequested event,
    Emitter<LogoutState> emit,
  ) async {
    emit(const LogoutState(LogoutStatus.inProgress));
    // Removes the token saved during sign-in from Hive.
    await _logoutUser();
    // Alarms belong to the account: disarm them so they can't keep ringing
    // for a guest or the next user.
    await AlarmScheduler.cancelAllAlarms();
    emit(const LogoutState(LogoutStatus.done));
  }
}
