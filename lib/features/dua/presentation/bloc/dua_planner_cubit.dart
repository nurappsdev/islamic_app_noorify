import 'package:bloc/bloc.dart';

import 'package:tuhfatul_muslim/features/dua/data/models/dua_plan_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/domain/repositories/dua_repository.dart';

enum DuaPlannerStatus { initial, loading, success, failure }

class DuaPlannerState {
  const DuaPlannerState({
    this.status = DuaPlannerStatus.initial,
    this.tab = 0,
    this.plans = const [],
    this.error,
  });

  /// 0 = "My Plan" (in progress), 1 = "Complete Plan".
  final DuaPlannerStatus status;
  final int tab;
  final List<DuaPlan> plans;
  final String? error;

  DuaPlannerState copyWith({
    DuaPlannerStatus? status,
    int? tab,
    List<DuaPlan>? plans,
    String? error,
    bool clearError = false,
  }) => DuaPlannerState(
    status: status ?? this.status,
    tab: tab ?? this.tab,
    plans: plans ?? this.plans,
    error: clearError ? null : (error ?? this.error),
  );
}

/// Loads the Dua planner's "My Plan" / "Complete Plan" tabs
/// (`GET /duas/planner/plans?status=...`), design `devImg/img_7.png`.
class DuaPlannerCubit extends Cubit<DuaPlannerState> {
  DuaPlannerCubit(this._repository) : super(const DuaPlannerState());
  final DuaRepository _repository;

  Future<void> selectTab(int tab) async {
    emit(state.copyWith(tab: tab));
    await load();
  }

  Future<void> load() async {
    emit(state.copyWith(status: DuaPlannerStatus.loading, clearError: true));
    try {
      final status = state.tab == 1 ? 'completed' : 'in_progress';
      final plans = await _repository.getPlans(status: status);
      emit(state.copyWith(status: DuaPlannerStatus.success, plans: plans));
    } catch (error) {
      emit(state.copyWith(status: DuaPlannerStatus.failure, error: '$error'));
    }
  }
}
