import 'package:bloc/bloc.dart';

import 'package:islami_app_noorify/features/home/domain/usecases/get_home_dashboard.dart';

import 'home_dashboard_event.dart';
import 'home_dashboard_state.dart';

export 'home_dashboard_event.dart';
export 'home_dashboard_state.dart';

class HomeDashboardBloc extends Bloc<HomeDashboardEvent, HomeDashboardState> {
  HomeDashboardBloc(this._getHomeDashboard)
    : super(const HomeDashboardState.initial()) {
    on<LoadHomeDashboard>(_onLoad);
  }

  final GetHomeDashboard _getHomeDashboard;

  Future<void> _onLoad(
    LoadHomeDashboard event,
    Emitter<HomeDashboardState> emit,
  ) async {
    // `GET /home/dashboard` is public: signed-out callers get generic
    // ("Guest User") content instead of a 401, so it's always worth calling.
    emit(const HomeDashboardState.loading());
    final result = await _getHomeDashboard();
    result.fold(
      (failure) => emit(HomeDashboardState.failure(failure)),
      (dashboard) => emit(HomeDashboardState.success(dashboard)),
    );
  }
}
