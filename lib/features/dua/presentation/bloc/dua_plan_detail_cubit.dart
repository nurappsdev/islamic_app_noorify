import 'package:bloc/bloc.dart';

import 'package:tuhfatul_muslim/features/dua/data/models/dua_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/data/models/dua_plan_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/domain/repositories/dua_repository.dart';

enum DuaPlanDetailStatus { initial, loading, success, failure }

/// One of the plan's duas, paired with its full content (`GET /duas/{id}`)
/// so it can be shown and opened for reading.
class DuaPlanDetailEntry {
  const DuaPlanDetailEntry({required this.dua, required this.item});
  final DuaFeaturedModel dua;
  final DuaPlanItem item;
}

class DuaPlanDetailState {
  const DuaPlanDetailState({
    this.status = DuaPlanDetailStatus.initial,
    this.planName = '',
    this.entries = const [],
    this.error,
  });

  final DuaPlanDetailStatus status;
  final String planName;
  final List<DuaPlanDetailEntry> entries;
  final String? error;

  DuaPlanDetailState copyWith({
    DuaPlanDetailStatus? status,
    String? planName,
    List<DuaPlanDetailEntry>? entries,
    String? error,
  }) => DuaPlanDetailState(
    status: status ?? this.status,
    planName: planName ?? this.planName,
    entries: entries ?? this.entries,
    error: error,
  );
}

/// Loads one plan's duas (`GET /duas/planner/plans/{id}`), design
/// `devImg/img_7.png`'s "My Plan" entry opened for reading.
///
/// The plan endpoint only guarantees each item's `duaId`/progress, so each
/// dua's full content is fetched separately (`GET /duas/{id}`) and paired up
/// for display.
class DuaPlanDetailCubit extends Cubit<DuaPlanDetailState> {
  DuaPlanDetailCubit(this._repository, {required this.planId})
    : super(const DuaPlanDetailState());

  final DuaRepository _repository;
  final String planId;

  Future<void> load() async {
    emit(state.copyWith(status: DuaPlanDetailStatus.loading));
    try {
      final detail = await _repository.getPlanDetail(planId);
      final duas = await Future.wait([
        for (final item in detail.items) _repository.getDuaById(item.duaId),
      ]);
      final entries = [
        for (var i = 0; i < detail.items.length; i++)
          DuaPlanDetailEntry(dua: duas[i], item: detail.items[i]),
      ];
      emit(
        state.copyWith(
          status: DuaPlanDetailStatus.success,
          planName: detail.name,
          entries: entries,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(status: DuaPlanDetailStatus.failure, error: '$error'),
      );
    }
  }
}
