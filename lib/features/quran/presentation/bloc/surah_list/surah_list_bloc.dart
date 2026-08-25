import 'package:bloc/bloc.dart';

import 'package:islami_app_noorify/features/quran/data/services/quran_api_service.dart';

import 'surah_list_event.dart';
import 'surah_list_state.dart';

export 'surah_list_event.dart';
export 'surah_list_state.dart';

class SurahListBloc extends Bloc<SurahListEvent, SurahListState> {
  SurahListBloc({QuranApiService? apiService})
    : _apiService = apiService ?? QuranApiPagesService(),
      super(const SurahListState()) {
    on<LoadSurahs>(_onLoad);
  }

  final QuranApiService _apiService;

  Future<void> _onLoad(LoadSurahs event, Emitter<SurahListState> emit) async {
    emit(state.copyWith(isLoading: true, hasError: false));
    try {
      final surahs = await _apiService.loadSurahList();
      emit(state.copyWith(isLoading: false, surahs: surahs));
    } catch (_) {
      emit(state.copyWith(isLoading: false, hasError: true));
    }
  }
}
