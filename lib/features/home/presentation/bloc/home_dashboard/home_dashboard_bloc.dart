import 'package:bloc/bloc.dart';

import 'package:tuhfatul_muslim/features/amol_tracking/domain/amol_tracking_day.dart';
import 'package:tuhfatul_muslim/features/home/domain/usecases/get_home_dashboard.dart';

import 'home_dashboard_event.dart';
import 'home_dashboard_state.dart';

export 'home_dashboard_event.dart';
export 'home_dashboard_state.dart';

class HomeDashboardBloc extends Bloc<HomeDashboardEvent, HomeDashboardState> {
  HomeDashboardBloc(this._getHomeDashboard, {DateTime Function()? now})
    : _now = now ?? DateTime.now,
      super(const HomeDashboardState.initial()) {
    on<LoadHomeDashboard>(_onLoad);
  }

  final GetHomeDashboard _getHomeDashboard;
  final DateTime Function() _now;
  bool _requestInFlight = false;

  /// The Amol tracking day the dashboard on screen was fetched for. Once the
  /// day has moved on, that dashboard is yesterday's: its daily points and
  /// percentages are no longer shown, not even while a reload is in flight
  /// or if the reload fails offline.
  String? _loadedDate;

  Future<void> _onLoad(
    LoadHomeDashboard event,
    Emitter<HomeDashboardState> emit,
  ) async {
    // Home refresh, the tracker-store listener, and a return from the Amol
    // screen can all request the same resource together. Only the first
    // request owns the network call; the others reuse its eventual state.
    if (_requestInFlight) return;
    _requestInFlight = true;

    // `GET /home/dashboard` is public: signed-out callers get generic
    // ("Guest User") content instead of a 401, so it's always worth calling.
    final today = amolTrackingDateIso(_now());
    final isNewDay = _loadedDate != null && _loadedDate != today;
    final keepShowing = event.silent && state.hasData && !isNewDay;
    try {
      if (!keepShowing) emit(const HomeDashboardState.loading());
      final result = await _getHomeDashboard();
      result.fold(
        (failure) {
          if (!keepShowing) emit(HomeDashboardState.failure(failure));
        },
        (dashboard) {
          _loadedDate = today;
          emit(HomeDashboardState.success(dashboard));
        },
      );
    } finally {
      _requestInFlight = false;
    }
  }
}
