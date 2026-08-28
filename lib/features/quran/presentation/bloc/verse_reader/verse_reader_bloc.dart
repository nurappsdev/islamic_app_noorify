import 'package:bloc/bloc.dart';

import 'package:islami_app_noorify/features/quran/data/services/quran_api_service.dart';
import 'package:islami_app_noorify/features/quran/data/services/quran_offline_first_service.dart';
import 'package:islami_app_noorify/features/quran/data/services/quran_offline_service.dart';
import 'package:islami_app_noorify/features/quran/data/services/quran_reader_service.dart';
import 'package:islami_app_noorify/features/quran/domain/verse_item.dart';

import 'verse_reader_event.dart';
import 'verse_reader_state.dart';

export 'verse_reader_event.dart';
export 'verse_reader_state.dart';

class VerseReaderBloc extends Bloc<VerseReaderEvent, VerseReaderState> {
  VerseReaderBloc({
    QuranOfflineService? offlineService,
    QuranReaderService? readerService,
    QuranApiService? apiService,
  }) : _offlineService = offlineService ?? QuranOfflineService(),
       _readerService = readerService ?? QuranComReaderService(),
       _apiService = apiService ?? QuranOfflineFirstService(),
       super(const VerseReaderState()) {
    on<LoadJuzVerses>((event, emit) => _load(emit, event.juzNumber));
  }

  final QuranOfflineService _offlineService;
  final QuranReaderService _readerService;
  final QuranApiService _apiService;

  Future<void> _load(Emitter<VerseReaderState> emit, int juzNumber) async {
    emit(state.copyWith(isLoading: true, hasError: false));
    try {
      final verses = await _loadVerses(juzNumber);
      final surahs = await _apiService.loadSurahList();
      emit(
        state.copyWith(
          isLoading: false,
          verses: verses,
          surahNames: {for (final surah in surahs) surah.number: surah.name},
        ),
      );
    } catch (_) {
      emit(state.copyWith(isLoading: false, hasError: true));
    }
  }

  Future<List<VerseItem>> _loadVerses(int juzNumber) async {
    try {
      final verses = await _offlineService.loadVersesByJuz(juzNumber);
      if (verses.isNotEmpty) return verses;
    } catch (_) {
      // fall through to the network
    }
    return _readerService.loadVersesByJuz(juzNumber);
  }
}
