import 'package:tuhfatul_muslim/features/quran/data/services/quran_content_service.dart'
    show QuranOfflineException;
import 'package:bloc/bloc.dart';

import 'package:tuhfatul_muslim/features/quran/data/services/quran_api_service.dart';
import 'package:tuhfatul_muslim/features/quran/data/services/quran_offline_first_service.dart';
import 'package:tuhfatul_muslim/features/quran/data/services/quran_offline_service.dart';
import 'package:tuhfatul_muslim/features/quran/data/services/quran_reader_service.dart';
import 'package:tuhfatul_muslim/features/quran/domain/juz_summary.dart';

import 'juz_list_event.dart';
import 'juz_list_state.dart';

export 'juz_list_event.dart';
export 'juz_list_state.dart';

class JuzListBloc extends Bloc<JuzListEvent, JuzListState> {
  JuzListBloc({
    QuranOfflineService? offlineService,
    QuranReaderService? readerService,
    QuranApiService? apiService,
  }) : _readerService = readerService ?? QuranComReaderService(),
       _apiService = apiService ?? QuranOfflineFirstService(),
       super(const JuzListState()) {
    on<LoadJuzList>(_onLoad);
  }

  final QuranReaderService _readerService;
  final QuranApiService _apiService;

  Future<void> _onLoad(LoadJuzList event, Emitter<JuzListState> emit) async {
    emit(state.copyWith(isLoading: true, hasError: false, offline: false));
    try {
      final juzs = await _loadJuzs();
      final surahs = await _apiService.loadSurahList();
      emit(
        state.copyWith(
          isLoading: false,
          juzs: juzs,
          surahNames: {for (final surah in surahs) surah.number: surah.name},
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          hasError: true,
          offline: e is QuranOfflineException,
        ),
      );
    }
  }

  Future<List<JuzSummary>> _loadJuzs() async {
    return _readerService.loadJuzList();
  }
}
