import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:bloc/bloc.dart';

import 'package:islami_app_noorify/features/quran/data/services/quran_audio_downloader.dart';
import 'package:islami_app_noorify/features/quran/data/services/quran_audio_handler.dart';

import 'ayah_audio_event.dart';
import 'ayah_audio_state.dart';

export 'ayah_audio_event.dart';
export 'ayah_audio_state.dart';

class _AyahCompleted extends AyahAudioEvent {
  const _AyahCompleted();
}

/// One shared instance per surah screen so only one ayah plays at a time.
///
/// Playback is offline-only: an ayah plays from its downloaded file, and if
/// the surah's audio has not been downloaded yet the bloc reports
/// [AyahAudioState.needsDownloadForVerseKey] so the screen can prompt a
/// download instead of streaming. Each ayah has its own repeat count
/// ([AyahAudioState.repeatCounts]); a played ayah repeats that many times
/// before playback stops.
class AyahAudioBloc extends Bloc<AyahAudioEvent, AyahAudioState> {
  AyahAudioBloc({QuranAudioDownloader? downloader, QuranAudioHandler? audio})
    : downloader = downloader ?? QuranAudioDownloader(),
      _audio = audio ?? quranAudioHandler,
      super(const AyahAudioState()) {
    _completedSub = _audio.onCompleted.listen(
      (_) => add(const _AyahCompleted()),
    );
    on<PlayAyahAudio>(_onPlay);
    on<StopAyahAudio>(_onStop);
    on<SetAyahRepeatCount>(_onSetRepeatCount);
    on<_AyahCompleted>(_onCompleted);
  }

  final QuranAudioDownloader downloader;
  final QuranAudioHandler _audio;
  late final StreamSubscription<void> _completedSub;
  int _recitationId = 0;

  void _onSetRepeatCount(
    SetAyahRepeatCount event,
    Emitter<AyahAudioState> emit,
  ) {
    final counts = Map<String, int>.from(state.repeatCounts);
    if (event.count <= 1) {
      counts.remove(event.verseKey);
    } else {
      counts[event.verseKey] = event.count;
    }
    emit(
      state.copyWith(
        repeatCounts: counts,
        // Apply immediately if this ayah is the one playing.
        remainingRepeats: state.playingVerseKey == event.verseKey
            ? event.count
            : null,
      ),
    );
  }

  Future<void> _onPlay(
    PlayAyahAudio event,
    Emitter<AyahAudioState> emit,
  ) async {
    await _audio.stopCurrent();
    if (!event.restart && state.playingVerseKey == event.verseKey) {
      emit(
        state.copyWith(
          clearPlayingVerseKey: true,
          isBuffering: false,
          remainingRepeats: 1,
        ),
      );
      return;
    }
    _recitationId = event.recitationId;
    emit(
      state.copyWith(
        playingVerseKey: event.verseKey,
        isBuffering: true,
        remainingRepeats: state.repeatCountFor(event.verseKey),
      ),
    );
    try {
      final localPath = await downloader.localPathFor(
        reciterId: event.recitationId,
        verseKey: event.verseKey,
      );
      if (state.playingVerseKey != event.verseKey) return;
      if (localPath == null) {
        // Pulse the flag so a repeat tap on the same ayah re-triggers the
        // screen's download prompt, then settle back to idle.
        emit(
          state.copyWith(
            clearPlayingVerseKey: true,
            isBuffering: false,
            needsDownloadForVerseKey: event.verseKey,
          ),
        );
        emit(state.copyWith(clearNeedsDownload: true));
        return;
      }
      await _audio.playFile(
        localPath,
        item: MediaItem(id: event.verseKey, title: 'Ayah ${event.verseKey}'),
      );
      emit(state.copyWith(playingVerseKey: event.verseKey, isBuffering: false));
    } catch (_) {
      emit(state.copyWith(clearPlayingVerseKey: true, isBuffering: false));
    }
  }

  Future<void> _onCompleted(
    _AyahCompleted event,
    Emitter<AyahAudioState> emit,
  ) async {
    final verseKey = state.playingVerseKey;
    if (verseKey == null) return;

    if (state.remainingRepeats > 1) {
      emit(
        state.copyWith(
          remainingRepeats: state.remainingRepeats - 1,
          isBuffering: true,
        ),
      );
      try {
        final localPath = await downloader.localPathFor(
          reciterId: _recitationId,
          verseKey: verseKey,
        );
        if (state.playingVerseKey != verseKey) return;
        if (localPath == null) {
          emit(state.copyWith(clearPlayingVerseKey: true, isBuffering: false));
          return;
        }
        await _audio.playFile(
          localPath,
          item: MediaItem(id: verseKey, title: 'Ayah $verseKey'),
        );
        emit(state.copyWith(isBuffering: false));
      } catch (_) {
        emit(state.copyWith(clearPlayingVerseKey: true, isBuffering: false));
      }
      return;
    }

    await _audio.stopCurrent();
    emit(
      state.copyWith(
        clearPlayingVerseKey: true,
        isBuffering: false,
        remainingRepeats: 1,
      ),
    );
  }

  Future<void> _onStop(
    StopAyahAudio event,
    Emitter<AyahAudioState> emit,
  ) async {
    await _audio.stopCurrent();
    emit(
      state.copyWith(
        clearPlayingVerseKey: true,
        isBuffering: false,
        remainingRepeats: 1,
      ),
    );
  }

  @override
  Future<void> close() {
    _completedSub.cancel();
    // Only tear down the shared engine if this bloc was the one driving it —
    // another screen (e.g. continuous surah playback) may have taken it over
    // since, and shouldn't be cut off by this bloc closing.
    if (state.playingVerseKey != null) _audio.stop();
    return super.close();
  }
}
