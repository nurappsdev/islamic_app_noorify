import 'package:bloc/bloc.dart';

import 'package:islami_app_noorify/features/hadith/domain/usecases/get_ebooks.dart';

import 'ebooks_event.dart';
import 'ebooks_state.dart';

export 'ebooks_event.dart';
export 'ebooks_state.dart';

class EbooksBloc extends Bloc<EbooksEvent, EbooksState> {
  EbooksBloc(this._getEbooks) : super(const EbooksState()) {
    on<LoadEbooks>(_onLoad);
  }

  final GetEbooks _getEbooks;

  Future<void> _onLoad(LoadEbooks event, Emitter<EbooksState> emit) async {
    emit(const EbooksState(status: EbooksStatus.loading));
    final result = await _getEbooks();
    result.fold(
      (failure) =>
          emit(EbooksState(status: EbooksStatus.failure, failure: failure)),
      (ebooks) =>
          emit(EbooksState(status: EbooksStatus.success, ebooks: ebooks)),
    );
  }
}
