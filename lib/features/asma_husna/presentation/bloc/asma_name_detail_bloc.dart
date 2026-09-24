import 'package:bloc/bloc.dart';

import 'package:islami_app_noorify/features/asma_husna/domain/usecases/get_asma_name_detail.dart';

import 'asma_name_detail_event.dart';
import 'asma_name_detail_state.dart';

export 'asma_name_detail_event.dart';
export 'asma_name_detail_state.dart';

/// Loads the full explanation for a single name, shown on
/// [AsmaNameDetailScreen].
class AsmaNameDetailBloc
    extends Bloc<AsmaNameDetailEvent, AsmaNameDetailState> {
  AsmaNameDetailBloc(this._getNameDetail) : super(const AsmaNameDetailState()) {
    on<LoadAsmaNameDetail>(_onLoad);
  }

  final GetAsmaNameDetail _getNameDetail;

  Future<void> _onLoad(
    LoadAsmaNameDetail event,
    Emitter<AsmaNameDetailState> emit,
  ) async {
    emit(state.copyWith(status: AsmaNameDetailStatus.loading));
    final result = await _getNameDetail(event.id);
    result.fold(
      (failure) => emit(
        state.copyWith(status: AsmaNameDetailStatus.failure, failure: failure),
      ),
      (detail) => emit(
        state.copyWith(status: AsmaNameDetailStatus.success, detail: detail),
      ),
    );
  }
}
