import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:bloc/bloc.dart';

import 'package:islami_app_noorify/features/quran/data/services/quran_audio_downloader.dart';
import 'package:islami_app_noorify/features/quran/data/services/quran_audio_handler.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/reciter/reciter_bloc.dart'
    show defaultRecitationId;

import 'surah_playback_event.dart';
import 'surah_playback_state.dart';

export 'surah_playback_event.dart';
export 'surah_playback_state.dart';

class _AdvanceAyah extends SurahPlaybackEvent {
  const _AdvanceAyah();
}

/// Plays a surah continuously from downloaded files: the opening Bismillah
/// clip (where the surah has one) followed by every ayah, auto-advancing as
/// each file finishes. If the surah's audio is not on the device the bloc
/// reports [SurahPlaybackState.needsDownload] instead of streaming.
class SurahPlaybackBloc extends Bloc<SurahPlaybackEvent, SurahPlaybackState> {
  SurahPlaybackBloc({
    QuranAudioDownloader? downloader,
    QuranAudioHandler? audio,
  }) : _downloader = downloader ?? QuranAudioDownloader(),
       _audio = audio ?? quranAudioHandler,
       super(const SurahPlaybackState()) {
    _completedSub = _audio.onCompleted.listen((_) => add(const _AdvanceAyah()));
    on<PlaySurah>(_onPlay);
    on<PauseSurah>(_onPause);
    on<SetActiveAyah>(
      (event, emit) =>
          emit(state.copyWith(currentAyahNo: event.ayahNo, isPlaying: false)),
    );
    on<SetRepeatCount>(
      (event, emit) => emit(
        state.copyWith(
          repeatCount: event.count,
          remainingRepeats: state.isPlaying
              ? state.remainingRepeats
              : event.count,
        ),
      ),
    );
    on<_AdvanceAyah>(_onAdvance);
  }

  /// Al-Fatiha and At-Tawbah do not open with the Basmala.
  static const _surahsWithoutBismillah = {1, 9};

  final QuranAudioDownloader _downloader;
  final QuranAudioHandler _audio;
  late final StreamSubscription<void> _completedSub;
  int _surahNo = 0;
  int _totalAyah = 0;
  int _recitationId = defaultRecitationId;

  bool get _hasBismillah => !_surahsWithoutBismillah.contains(_surahNo);

  /// Briefly raises [SurahPlaybackState.needsDownload] so a listener fires,
  /// then lowers it — a repeat play tap re-triggers the download prompt.
  void _pulseNeedsDownload(Emitter<SurahPlaybackState> emit) {
    emit(
      state.copyWith(isPlaying: false, isBuffering: false, needsDownload: true),
    );
    emit(state.copyWith(needsDownload: false));
  }

  Future<void> _onPlay(
    PlaySurah event,
    Emitter<SurahPlaybackState> emit,
  ) async {
    _surahNo = event.surahNo;
    _totalAyah = event.totalAyah;
    _recitationId = event.recitationId;

    final complete = await _downloader.isSurahComplete(
      reciterId: _recitationId,
      surahNo: _surahNo,
      totalAyah: _totalAyah,
    );
    if (!complete) {
      _pulseNeedsDownload(emit);
      return;
    }

    emit(state.copyWith(remainingRepeats: state.repeatCount));

    // Start from the Bismillah (ayah 0) when playing a surah from the top.
    final startAt = state.currentAyahNo <= 1 && _hasBismillah
        ? 0
        : state.currentAyahNo;
    await _playAyah(startAt, emit);
  }

  Future<void> _onPause(
    PauseSurah event,
    Emitter<SurahPlaybackState> emit,
  ) async {
    await _audio.pause();
    emit(state.copyWith(isPlaying: false));
  }

  Future<void> _onAdvance(
    _AdvanceAyah event,
    Emitter<SurahPlaybackState> emit,
  ) async {
    if (!state.isPlaying) return;
    final next = state.currentAyahNo + 1;
    if (next > _totalAyah) {
      if (state.remainingRepeats > 1) {
        emit(state.copyWith(remainingRepeats: state.remainingRepeats - 1));
        final startAt = _hasBismillah ? 0 : 1;
        await _playAyah(startAt, emit);
      } else {
        emit(state.copyWith(isPlaying: false, remainingRepeats: 1));
      }
      return;
    }
    await _playAyah(next, emit);
  }

  Future<void> _playAyah(int ayahNo, Emitter<SurahPlaybackState> emit) async {
    emit(
      state.copyWith(
        currentAyahNo: ayahNo,
        isPlaying: true,
        isBuffering: true,
        needsDownload: false,
      ),
    );
    try {
      final localPath = ayahNo == 0
          ? await _downloader.localBismillahPath(_recitationId)
          : await _downloader.localPathFor(
              reciterId: _recitationId,
              verseKey: '$_surahNo:$ayahNo',
            );
      if (!state.isPlaying || state.currentAyahNo != ayahNo) return;
      if (localPath == null) {
        // A missing Bismillah file should not block the recitation itself.
        if (ayahNo == 0) {
          await _playAyah(1, emit);
          return;
        }
        _pulseNeedsDownload(emit);
        return;
      }
      await _audio.playFile(
        localPath,
        item: MediaItem(
          id: '$_surahNo:$ayahNo',
          title: ayahNo == 0 ? 'Bismillah' : 'Ayah $ayahNo',
          album: 'Surah $_surahNo',
        ),
      );
      emit(state.copyWith(isBuffering: false));
    } catch (_) {
      emit(state.copyWith(isPlaying: false, isBuffering: false));
    }
  }

  @override
  Future<void> close() {
    _completedSub.cancel();
    // Only tear down the shared engine if this bloc was the one driving it —
    // another screen (e.g. a single-ayah preview) may have taken it over
    // since, and its playback shouldn't be cut off by this bloc closing.
    if (state.isPlaying) _audio.stop();
    return super.close();
  }
}
