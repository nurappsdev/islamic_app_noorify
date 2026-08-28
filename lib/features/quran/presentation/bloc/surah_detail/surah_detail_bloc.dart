import 'package:bloc/bloc.dart';

import 'package:islami_app_noorify/features/quran/data/services/quran_api_service.dart';
import 'package:islami_app_noorify/features/quran/data/services/quran_offline_first_service.dart';

import 'surah_detail_event.dart';
import 'surah_detail_state.dart';

export 'surah_detail_event.dart';
export 'surah_detail_state.dart';

class SurahDetailBloc extends Bloc<SurahDetailEvent, SurahDetailState> {
  SurahDetailBloc({QuranApiService? apiService})
    : _apiService = apiService ?? QuranOfflineFirstService(),
      super(const SurahDetailState()) {
    on<LoadSurahDetail>(_onLoad);
  }

  final QuranApiService _apiService;

  Future<void> _onLoad(
    LoadSurahDetail event,
    Emitter<SurahDetailState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, hasError: false));
    try {
      final detail = await _apiService.loadSurahDetail(event.surahNo);
      emit(state.copyWith(isLoading: false, detail: detail));
    } catch (_) {
      emit(state.copyWith(isLoading: false, hasError: true));
    }
  }
}
