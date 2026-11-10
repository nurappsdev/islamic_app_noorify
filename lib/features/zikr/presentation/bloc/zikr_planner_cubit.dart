import 'package:bloc/bloc.dart';

import 'package:tuhfatul_muslim/features/zikr/data/models/zikr_api_models.dart';
import 'package:tuhfatul_muslim/features/zikr/domain/repositories/zikr_repository.dart';
import 'package:tuhfatul_muslim/features/zikr/presentation/bloc/zikr_home_cubit.dart';

class ZikrPlannerState {
  const ZikrPlannerState({
    this.status = ZikrLoadStatus.initial,
    this.tab = 0,
    this.plans = const [],
    this.error,
  });
  final ZikrLoadStatus status;
  final int tab;
  final List<ZikrPlan> plans;
  final String? error;
  ZikrPlannerState copyWith({
    ZikrLoadStatus? status,
    int? tab,
    List<ZikrPlan>? plans,
    String? error,
    bool clearError = false,
  }) => ZikrPlannerState(
    status: status ?? this.status,
    tab: tab ?? this.tab,
    plans: plans ?? this.plans,
    error: clearError ? null : (error ?? this.error),
  );
}

class ZikrPlannerCubit extends Cubit<ZikrPlannerState> {
  ZikrPlannerCubit(this._repository) : super(const ZikrPlannerState());
  final ZikrRepository _repository;

  Future<void> selectTab(int tab) async {
    emit(state.copyWith(tab: tab));
    await load();
  }

  Future<void> load() async {
    emit(state.copyWith(status: ZikrLoadStatus.loading, clearError: true));
    try {
      final plans = switch (state.tab) {
        0 => await _repository.getPlans(status: 'active'),
        1 => await _repository.getPlans(type: 'preset'),
        _ => await _repository.getPlans(status: 'completed'),
      };
      emit(state.copyWith(status: ZikrLoadStatus.success, plans: plans));
    } catch (error) {
      emit(state.copyWith(status: ZikrLoadStatus.failure, error: '$error'));
    }
  }

  Future<void> enroll(String id) async {
    await _repository.enrollPlan(id);
    await selectTab(0);
  }

  Future<void> delete(String id) async {
    await _repository.deletePlan(id);
    await load();
  }

  Future<ZikrPlan> create(Map<String, dynamic> body) =>
      _repository.createPlan(body);
}
