import 'package:bloc/bloc.dart';

import 'package:islami_app_noorify/features/quran/data/services/quran_reader_service.dart';

import 'tafsir_event.dart';
import 'tafsir_state.dart';

export 'tafsir_event.dart';
export 'tafsir_state.dart';

/// English tafsir: Ibn Kathir (Abridged).
const englishTafsirResourceId = 169;

/// Bangla tafsir: Tafsir Ahsanul Bayaan.
const banglaTafsirResourceId = 165;

class TafsirBloc extends Bloc<TafsirEvent, TafsirState> {
  TafsirBloc({required this.tafsirResourceId, QuranReaderService? readerService})
    : _readerService = readerService ?? QuranComReaderService(),
      super(const TafsirState()) {
    on<LoadTafsir>(_onLoad);
  }

  final int tafsirResourceId;
  final QuranReaderService _readerService;

  Future<void> _onLoad(LoadTafsir event, Emitter<TafsirState> emit) async {
    emit(state.copyWith(isLoading: true, hasError: false));
    try {
      final text = await _readerService.loadTafsir(
        tafsirResourceId,
        event.verseKey,
      );
      emit(state.copyWith(isLoading: false, text: text));
    } catch (_) {
      emit(state.copyWith(isLoading: false, hasError: true));
    }
  }
}
