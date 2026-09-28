import 'dart:async';

import 'package:bloc/bloc.dart';

import 'package:islami_app_noorify/features/amol_tracking/domain/entities/amol_daily_dashboard.dart';
import 'package:islami_app_noorify/features/amol_tracking/domain/usecases/delete_amol_item.dart';
import 'package:islami_app_noorify/features/amol_tracking/domain/usecases/get_amol_daily.dart';
import 'package:islami_app_noorify/features/amol_tracking/domain/usecases/log_amol_item.dart';

import 'amol_daily_event.dart';
import 'amol_daily_state.dart';

export 'amol_daily_event.dart';
export 'amol_daily_state.dart';

class AmolDailyBloc extends Bloc<AmolDailyEvent, AmolDailyState> {
  /// [initialDashboard] - today's checklist already fetched elsewhere (the
  /// Home cards' shared store) - is shown straight away; a [LoadAmolDaily] with
  /// `silent: true` then refreshes it in the background.
  AmolDailyBloc(
    this._getAmolDaily,
    this._logAmolItem,
    this._deleteAmolItem, {
    AmolDailyDashboard? initialDashboard,
  }) : super(
         initialDashboard == null
             ? const AmolDailyState.initial()
             : AmolDailyState.success(initialDashboard),
       ) {
    on<LoadAmolDaily>(_onLoad);
    on<LogAmolDailyItem>(_onLogItem);
    on<UncheckAmolDailyItem>(_onUncheckItem);
  }

  final GetAmolDaily _getAmolDaily;
  final LogAmolItem _logAmolItem;
  final DeleteAmolItem _deleteAmolItem;

  /// One-off notifications for a failed `log-item`/`delete-item` call (the
  /// main [state]/dashboard is left untouched on that failure, so this is
  /// the only signal the screen gets — typically surfaced as a SnackBar).
  final _logFailures = StreamController<String>.broadcast();
  Stream<String> get logFailures => _logFailures.stream;

  Future<void> _onLoad(
    LoadAmolDaily event,
    Emitter<AmolDailyState> emit,
  ) async {
    // Carried across the reload: the server's `isCompleted` isn't trusted
    // to stay consistent between calls, so once the user has checked or
    // unchecked an item this session it stays that way regardless of what
    // this `GET` reports.
    final completionOverrides = state.completionOverrides;
    final refreshInPlace = event.silent && state.hasData;
    if (!refreshInPlace) {
      emit(AmolDailyState.loading(completionOverrides: completionOverrides));
    }
    final result = await _getAmolDaily(date: event.date);
    result.fold(
      // A silent refresh that fails keeps the checklist that is showing.
      (failure) => refreshInPlace
          ? null
          : emit(
              AmolDailyState.failure(
                failure,
                completionOverrides: completionOverrides,
              ),
            ),
      (dashboard) => emit(
        AmolDailyState.success(
          dashboard,
          completionOverrides: completionOverrides,
        ),
      ),
    );
  }

  Future<void> _onLogItem(
    LogAmolDailyItem event,
    Emitter<AmolDailyState> emit,
  ) async {
    // One in flight at a time.
    if (state.loggingItemKey != null) return;

    // Check it immediately and keep it checked no matter what `log-item`
    // comes back with — see [AmolDailyState.completionOverrides].
    emit(state.withOptimisticCompletion(event.itemKey, true));
    final completionOverrides = state.completionOverrides;
    final result = await _logAmolItem(
      logDate: event.logDate,
      pillarKey: event.pillarKey,
      itemKey: event.itemKey,
    );
    result.fold(
      (failure) {
        _logFailures.add(failure.message);
        emit(state.withLoggingItemKey(null));
      },
      (dashboard) => emit(
        AmolDailyState.success(
          dashboard,
          completionOverrides: completionOverrides,
        ),
      ),
    );
  }

  Future<void> _onUncheckItem(
    UncheckAmolDailyItem event,
    Emitter<AmolDailyState> emit,
  ) async {
    // One in flight at a time.
    if (state.loggingItemKey != null) return;

    // Uncheck it immediately and keep it unchecked no matter what
    // `delete-item` comes back with — see
    // [AmolDailyState.completionOverrides].
    emit(state.withOptimisticCompletion(event.itemKey, false));
    final completionOverrides = state.completionOverrides;
    final result = await _deleteAmolItem(
      logDate: event.logDate,
      pillarKey: event.pillarKey,
      itemKey: event.itemKey,
    );
    result.fold(
      (failure) {
        _logFailures.add(failure.message);
        emit(state.withLoggingItemKey(null));
      },
      (dashboard) => emit(
        AmolDailyState.success(
          dashboard,
          completionOverrides: completionOverrides,
        ),
      ),
    );
  }

  @override
  Future<void> close() {
    unawaited(_logFailures.close());
    return super.close();
  }
}
