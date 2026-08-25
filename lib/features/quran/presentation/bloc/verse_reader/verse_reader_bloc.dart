import 'package:bloc/bloc.dart';

import 'package:islami_app_noorify/features/quran/data/services/quran_api_service.dart';
import 'package:islami_app_noorify/features/quran/data/services/quran_reader_service.dart';
import 'package:islami_app_noorify/features/quran/domain/verse_item.dart';

import 'verse_reader_event.dart';
import 'verse_reader_state.dart';

export 'verse_reader_event.dart';
export 'verse_reader_state.dart';

class VerseReaderBloc extends Bloc<VerseReaderEvent, VerseReaderState> {
  VerseReaderBloc({QuranReaderService? readerService, QuranApiService? apiService})
    : _readerService = readerService ?? QuranComReaderService(),
      _apiService = apiService ?? QuranApiPagesService(),
      super(const VerseReaderState()) {
    on<LoadJuzVerses>(
      (event, emit) =>
          _load(emit, () => _readerService.loadVersesByJuz(event.juzNumber)),
    );
  }

  final QuranReaderService _readerService;
  final QuranApiService _apiService;

  Future<void> _load(
    Emitter<VerseReaderState> emit,
    Future<List<VerseItem>> Function() loader,
  ) async {
    emit(state.copyWith(isLoading: true, hasError: false));
    try {
      final verses = await loader();
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
}
