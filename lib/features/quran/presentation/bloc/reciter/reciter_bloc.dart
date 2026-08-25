import 'package:bloc/bloc.dart';

import 'package:islami_app_noorify/features/quran/data/services/quran_reader_service.dart';

import 'reciter_event.dart';
import 'reciter_state.dart';

export 'reciter_event.dart';
export 'reciter_state.dart';

/// Default reciter (Mishari Rashid al-`Afasy) used until the list of
/// reciters has loaded or the user picks a different one.
const defaultRecitationId = 7;

class ReciterBloc extends Bloc<ReciterEvent, ReciterState> {
  ReciterBloc({QuranReaderService? readerService})
    : _readerService = readerService ?? QuranComReaderService(),
      super(const ReciterState(selectedId: defaultRecitationId)) {
    on<LoadReciters>(_onLoad);
    on<SelectReciter>(
      (event, emit) => emit(state.copyWith(selectedId: event.recitationId)),
    );
  }

  final QuranReaderService _readerService;

  Future<void> _onLoad(LoadReciters event, Emitter<ReciterState> emit) async {
    try {
      final reciters = await _readerService.loadReciters();
      emit(state.copyWith(isLoading: false, reciters: reciters));
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }
}
