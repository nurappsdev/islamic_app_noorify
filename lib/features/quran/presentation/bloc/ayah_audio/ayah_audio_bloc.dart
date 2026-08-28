import 'package:audioplayers/audioplayers.dart';
import 'package:bloc/bloc.dart';

import 'package:islami_app_noorify/features/quran/data/services/quran_audio_downloader.dart';

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
/// download instead of streaming. A tapped ayah repeats
/// [AyahAudioState.repeatCount] times before playback stops.
class AyahAudioBloc extends Bloc<AyahAudioEvent, AyahAudioState> {
  AyahAudioBloc({QuranAudioDownloader? downloader})
    : downloader = downloader ?? QuranAudioDownloader(),
      super(const AyahAudioState()) {
    _player.onPlayerComplete.listen((_) => add(const _AyahCompleted()));
    on<PlayAyahAudio>(_onPlay);
    on<StopAyahAudio>(_onStop);
    on<SetAyahRepeatCount>(
      (event, emit) => emit(
        state.copyWith(repeatCount: event.count, remainingRepeats: event.count),
      ),
    );
    on<_AyahCompleted>(_onCompleted);
  }

  final QuranAudioDownloader downloader;
  final AudioPlayer _player = AudioPlayer();
  int _recitationId = 0;

  Future<void> _onPlay(
    PlayAyahAudio event,
    Emitter<AyahAudioState> emit,
  ) async {
    await _player.stop();
    if (!event.restart && state.playingVerseKey == event.verseKey) {
      emit(
        state.copyWith(
          clearPlayingVerseKey: true,
          isBuffering: false,
          remainingRepeats: state.repeatCount,
        ),
      );
      return;
    }
    _recitationId = event.recitationId;
    emit(
      state.copyWith(
        playingVerseKey: event.verseKey,
        isBuffering: true,
        remainingRepeats: state.repeatCount,
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
      await _player.play(DeviceFileSource(localPath));
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
        await _player.play(DeviceFileSource(localPath));
        emit(state.copyWith(isBuffering: false));
      } catch (_) {
        emit(state.copyWith(clearPlayingVerseKey: true, isBuffering: false));
      }
      return;
    }

    await _player.stop();
    emit(
      state.copyWith(
        clearPlayingVerseKey: true,
        isBuffering: false,
        remainingRepeats: state.repeatCount,
      ),
    );
  }

  Future<void> _onStop(
    StopAyahAudio event,
    Emitter<AyahAudioState> emit,
  ) async {
    await _player.stop();
    emit(
      state.copyWith(
        clearPlayingVerseKey: true,
        isBuffering: false,
        remainingRepeats: state.repeatCount,
      ),
    );
  }

  @override
  Future<void> close() {
    _player.dispose();
    return super.close();
  }
}
