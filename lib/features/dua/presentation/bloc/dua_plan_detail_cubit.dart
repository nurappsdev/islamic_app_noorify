import 'package:bloc/bloc.dart';

import 'package:tuhfatul_muslim/features/dua/data/models/dua_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/data/models/dua_plan_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/domain/repositories/dua_repository.dart';

enum DuaPlanDetailStatus { initial, loading, success, failure }

/// One of the plan's duas, paired with its full content so it can be shown
/// and opened for reading.
class DuaPlanDetailEntry {
  const DuaPlanDetailEntry({required this.dua, required this.item});
  final DuaFeaturedModel dua;
  final DuaPlanItem item;
}

class DuaPlanDetailState {
  const DuaPlanDetailState({
    this.status = DuaPlanDetailStatus.initial,
    this.planName = '',
    this.planStatus = 'in_progress',
    this.entries = const [],
    this.error,
  });

  final DuaPlanDetailStatus status;
  final String planName;

  /// `in_progress`, `completed` or `abandoned`.
  final String planStatus;
  final List<DuaPlanDetailEntry> entries;
  final String? error;

  DuaPlanDetailState copyWith({
    DuaPlanDetailStatus? status,
    String? planName,
    String? planStatus,
    List<DuaPlanDetailEntry>? entries,
    String? error,
  }) => DuaPlanDetailState(
    status: status ?? this.status,
    planName: planName ?? this.planName,
    planStatus: planStatus ?? this.planStatus,
    entries: entries ?? this.entries,
    error: error,
  );
}

/// Loads one plan's duas (`GET /duas/planner/plans/{id}`), design
/// `devImg/img_7.png`'s "My Plan" entry opened for reading.
///
/// The confirmed response embeds each item's full dua content under `dua`,
/// so this is normally a single request; `GET /duas/{id}` is only a fallback
/// for an item that (unexpectedly) doesn't carry it.
class DuaPlanDetailCubit extends Cubit<DuaPlanDetailState> {
  DuaPlanDetailCubit(this._repository, {required this.planId})
    : super(const DuaPlanDetailState());

  final DuaRepository _repository;
  final String planId;

  Future<void> load() async {
    emit(state.copyWith(status: DuaPlanDetailStatus.loading));
    try {
      final detail = await _repository.getPlanDetail(planId);
      final entries = await Future.wait([
        for (final item in detail.items) _entryFor(item),
      ]);
      emit(
        state.copyWith(
          status: DuaPlanDetailStatus.success,
          planName: detail.name,
          planStatus: detail.status,
          entries: entries,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(status: DuaPlanDetailStatus.failure, error: '$error'),
      );
    }
  }

  Future<DuaPlanDetailEntry> _entryFor(DuaPlanItem item) async {
    final dua = item.dua ?? await _repository.getDuaById(item.duaId);
    return DuaPlanDetailEntry(dua: dua, item: item);
  }
}
