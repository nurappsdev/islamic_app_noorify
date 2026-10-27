import 'dart:async';

import 'package:bloc/bloc.dart';

import 'package:tuhfatul_muslim/features/amol_tracking/domain/entities/amol_daily_dashboard.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/amol_local_projection.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/usecases/delete_amol_item.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/usecases/get_amol_daily.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/usecases/log_amol_item.dart';
import 'package:tuhfatul_muslim/features/quran/data/services/quran_offline_reading_progress_store.dart';

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
    QuranOfflineReadingProgressStore? offlineQuranProgress,
  }) : _offlineQuranProgress =
           offlineQuranProgress ?? QuranOfflineReadingProgressStore.shared,
       super(
         initialDashboard == null
             ? const AmolDailyState.initial()
             : AmolDailyState.success(initialDashboard),
       ) {
    on<LoadAmolDaily>(_onLoad);
    on<UseAmolDailyDashboard>(_onUseSharedDashboard);
    on<RefreshOfflineQuranProgress>(_onRefreshOfflineQuranProgress);
    on<LogAmolDailyItem>(_onLogItem);
    on<UncheckAmolDailyItem>(_onUncheckItem);
    _offlineQuranProgress.addListener(_onOfflineQuranProgressChanged);
  }

  final GetAmolDaily _getAmolDaily;
  final LogAmolItem _logAmolItem;
  final DeleteAmolItem _deleteAmolItem;
  final QuranOfflineReadingProgressStore _offlineQuranProgress;

  /// Every load owns a generation. This prevents a slow response for the
  /// previous civil day from restoring yesterday's checklist after midnight.
  int _loadGeneration = 0;
  String? _activeDate;

  /// The unprojected result of the last checklist request. Quran's device
  /// duration is always applied over this value, never over a prior projected
  /// result, so every five-minute point is counted exactly once.
  AmolDailyDashboard? _serverDashboard;

  /// One-off notifications for a failed `log-item`/`delete-item` call (the
  /// main [state]/dashboard is left untouched on that failure, so this is
  /// the only signal the screen gets — typically surfaced as a SnackBar).
  final _logFailures = StreamController<String>.broadcast();
  Stream<String> get logFailures => _logFailures.stream;

  void _onUseSharedDashboard(
    UseAmolDailyDashboard event,
    Emitter<AmolDailyState> emit,
  ) {
    // The shared store has already applied its local Quran projection.
    // Discard a previous raw baseline so another local notification cannot
    // add the same seconds a second time.
    _serverDashboard = null;
    emit(
      AmolDailyState.success(
        event.dashboard,
        completionOverrides: state.completionOverrides,
        loggingItemKeys: state.loggingItemKeys,
      ),
    );
  }

  void _onOfflineQuranProgressChanged() {
    if (!isClosed) add(const RefreshOfflineQuranProgress());
  }

  void _onRefreshOfflineQuranProgress(
    RefreshOfflineQuranProgress event,
    Emitter<AmolDailyState> emit,
  ) {
    final server = _serverDashboard;
    if (server == null || server.dateIso != _activeDate) return;
    emit(
      AmolDailyState.success(
        _projectOfflineQuran(server),
        completionOverrides: state.completionOverrides,
        loggingItemKeys: state.loggingItemKeys,
      ),
    );
  }

  AmolDailyDashboard _projectOfflineQuran(AmolDailyDashboard dashboard) {
    final date = dashboard.dateIso;
    return projectOfflineQuranReading(
      dashboard,
      // A report acknowledged by the Quran API is left for the shared Amol
      // store to reconcile against its next fresh daily response. This bloc
      // only owns reports still waiting on this device, so it can never add
      // a report that an online response already contains.
      additionalSeconds: _offlineQuranProgress
          .progressFor(
            date,
            acknowledgedInBaseline: _offlineQuranProgress.acknowledgedIdsFor(
              date,
            ),
          )
          .seconds,
    );
  }

  Future<void> _onLoad(
    LoadAmolDaily event,
    Emitter<AmolDailyState> emit,
  ) async {
    // Carried across the reload: the server's `isCompleted` isn't trusted
    // to stay consistent between calls, so once the user has checked or
    // unchecked an item this session it stays that way regardless of what
    // this `GET` reports.
    final loadGeneration = ++_loadGeneration;
    final isNewDay = _activeDate != event.date;
    _activeDate = event.date;
    // A locally-toggled item must never be carried into a new civil day.
    final completionOverrides = isNewDay
        ? const <String, bool>{}
        : state.completionOverrides;
    final refreshInPlace = event.silent && state.hasData;
    if (!refreshInPlace) {
      emit(AmolDailyState.loading(completionOverrides: completionOverrides));
    }
    final result = await _getAmolDaily(date: event.date);
    if (loadGeneration != _loadGeneration) return;
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
      (dashboard) {
        _serverDashboard = dashboard;
        emit(
          AmolDailyState.success(
            _projectOfflineQuran(dashboard),
            completionOverrides: completionOverrides,
          ),
        );
      },
    );
  }

  Future<void> _onLogItem(
    LogAmolDailyItem event,
    Emitter<AmolDailyState> emit,
  ) async {
    // Only this item's own request is awaited; ticking other items
    // meanwhile is allowed, so nothing done offline is dropped while a
    // request sits waiting for a network that isn't there.
    if (state.loggingItemKeys.contains(event.itemKey) ||
        _activeDate != event.logDate) {
      return;
    }

    // Check it immediately and keep it checked no matter what `log-item`
    // comes back with — see [AmolDailyState.completionOverrides].
    emit(state.withOptimisticCompletion(event.itemKey, true));
    final completionOverrides = state.completionOverrides;
    final result = await _logAmolItem(
      logDate: event.logDate,
      pillarKey: event.pillarKey,
      itemKey: event.itemKey,
    );
    if (_activeDate != event.logDate) return;
    result.fold(
      (failure) {
        _logFailures.add(failure.message);
        emit(state.withoutLoggingItem(event.itemKey));
      },
      (dashboard) {
        _serverDashboard = dashboard;
        emit(
          AmolDailyState.success(
            _projectOfflineQuran(dashboard),
            completionOverrides: completionOverrides,
            loggingItemKeys: state.loggingItemKeys.difference({event.itemKey}),
          ),
        );
      },
    );
  }

  Future<void> _onUncheckItem(
    UncheckAmolDailyItem event,
    Emitter<AmolDailyState> emit,
  ) async {
    // As in [_onLogItem]: only this item is held, so a run of unticks made
    // offline is all kept.
    if (state.loggingItemKeys.contains(event.itemKey) ||
        _activeDate != event.logDate) {
      return;
    }

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
    if (_activeDate != event.logDate) return;
    result.fold(
      (failure) {
        _logFailures.add(failure.message);
        emit(state.withoutLoggingItem(event.itemKey));
      },
      (dashboard) {
        _serverDashboard = dashboard;
        emit(
          AmolDailyState.success(
            _projectOfflineQuran(dashboard),
            completionOverrides: completionOverrides,
            loggingItemKeys: state.loggingItemKeys.difference({event.itemKey}),
          ),
        );
      },
    );
  }

  @override
  Future<void> close() {
    _offlineQuranProgress.removeListener(_onOfflineQuranProgressChanged);
    unawaited(_logFailures.close());
    return super.close();
  }
}
