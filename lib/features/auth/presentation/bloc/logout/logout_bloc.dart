import 'package:bloc/bloc.dart';

import 'package:islami_app_noorify/core/storage/session_cleaner.dart';
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
    // Then wipe everything else tied to the account (cached profile, alarms,
    // hadith bookmarks/progress, Quran progress, in-memory profile state) so
    // the next login can't see this user's data.
    await SessionCleaner.clearUserData();
    emit(const LogoutState(LogoutStatus.done));
  }
}
