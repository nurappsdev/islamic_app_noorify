import 'package:audioplayers/audioplayers.dart';
import 'package:bloc/bloc.dart';

import 'package:islami_app_noorify/features/quran/data/services/quran_reader_service.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/reciter/reciter_bloc.dart'
    show defaultRecitationId;

import 'surah_playback_event.dart';
import 'surah_playback_state.dart';

export 'surah_playback_event.dart';
export 'surah_playback_state.dart';

class _AdvanceAyah extends SurahPlaybackEvent {
  const _AdvanceAyah();
}

/// Plays a surah sequentially, ayah by ayah, auto-advancing when each
/// ayah's audio finishes.
class SurahPlaybackBloc extends Bloc<SurahPlaybackEvent, SurahPlaybackState> {
  SurahPlaybackBloc({QuranReaderService? readerService})
    : _readerService = readerService ?? QuranComReaderService(),
      super(const SurahPlaybackState()) {
    _player.onPlayerComplete.listen((_) => add(const _AdvanceAyah()));
    on<PlaySurah>(_onPlay);
    on<PauseSurah>(_onPause);
    on<SetActiveAyah>(
      (event, emit) =>
          emit(state.copyWith(currentAyahNo: event.ayahNo, isPlaying: false)),
    );
    on<_AdvanceAyah>(_onAdvance);
  }

  final QuranReaderService _readerService;
  final AudioPlayer _player = AudioPlayer();
  int _surahNo = 0;
  int _totalAyah = 0;
  int _recitationId = defaultRecitationId;

  Future<void> _onPlay(
    PlaySurah event,
    Emitter<SurahPlaybackState> emit,
  ) async {
    _surahNo = event.surahNo;
    _totalAyah = event.totalAyah;
    _recitationId = event.recitationId;
    await _playAyah(state.currentAyahNo, emit);
  }

  Future<void> _onPause(
    PauseSurah event,
    Emitter<SurahPlaybackState> emit,
  ) async {
    await _player.pause();
    emit(state.copyWith(isPlaying: false));
  }

  Future<void> _onAdvance(
    _AdvanceAyah event,
    Emitter<SurahPlaybackState> emit,
  ) async {
    if (!state.isPlaying) return;
    final next = state.currentAyahNo + 1;
    if (next > _totalAyah) {
      emit(state.copyWith(isPlaying: false));
      return;
    }
    await _playAyah(next, emit);
  }

  Future<void> _playAyah(int ayahNo, Emitter<SurahPlaybackState> emit) async {
    await _player.stop();
    emit(
      state.copyWith(
        currentAyahNo: ayahNo,
        isPlaying: true,
        isBuffering: true,
      ),
    );
    try {
      final url = await _readerService.loadAyahAudioUrl(
        _recitationId,
        '$_surahNo:$ayahNo',
      );
      if (!state.isPlaying || state.currentAyahNo != ayahNo) return;
      await _player.play(UrlSource(url));
      emit(state.copyWith(isBuffering: false));
    } catch (_) {
      emit(state.copyWith(isPlaying: false, isBuffering: false));
    }
  }

  @override
  Future<void> close() {
    _player.dispose();
    return super.close();
  }
}
