import 'package:audioplayers/audioplayers.dart';
import 'package:bloc/bloc.dart';

import 'package:islami_app_noorify/features/quran/data/services/quran_audio_downloader.dart';

import 'ayah_audio_event.dart';
import 'ayah_audio_state.dart';

export 'ayah_audio_event.dart';
export 'ayah_audio_state.dart';

/// One shared instance per surah screen so only one ayah plays at a time.
///
/// Playback is offline-only: an ayah plays from its downloaded file, and if
/// the surah's audio has not been downloaded yet the bloc reports
/// [AyahAudioState.needsDownloadForVerseKey] so the screen can prompt a
/// download instead of streaming.
class AyahAudioBloc extends Bloc<AyahAudioEvent, AyahAudioState> {
  AyahAudioBloc({QuranAudioDownloader? downloader})
    : downloader = downloader ?? QuranAudioDownloader(),
      super(const AyahAudioState()) {
    _player.onPlayerComplete.listen((_) => add(const StopAyahAudio()));
    on<PlayAyahAudio>(_onPlay);
    on<StopAyahAudio>(_onStop);
  }

  final QuranAudioDownloader downloader;
  final AudioPlayer _player = AudioPlayer();

  Future<void> _onPlay(
    PlayAyahAudio event,
    Emitter<AyahAudioState> emit,
  ) async {
    await _player.stop();
    if (!event.restart && state.playingVerseKey == event.verseKey) {
      emit(const AyahAudioState());
      return;
    }
    emit(AyahAudioState(playingVerseKey: event.verseKey, isBuffering: true));
    try {
      final localPath = await downloader.localPathFor(
        reciterId: event.recitationId,
        verseKey: event.verseKey,
      );
      if (state.playingVerseKey != event.verseKey) return;
      if (localPath == null) {
        // Pulse the flag so a repeat tap on the same ayah re-triggers the
        // screen's download prompt, then settle back to idle.
        emit(AyahAudioState(needsDownloadForVerseKey: event.verseKey));
        emit(const AyahAudioState());
        return;
      }
      await _player.play(DeviceFileSource(localPath));
      emit(AyahAudioState(playingVerseKey: event.verseKey));
    } catch (_) {
      emit(const AyahAudioState());
    }
  }

  Future<void> _onStop(
    StopAyahAudio event,
    Emitter<AyahAudioState> emit,
  ) async {
    await _player.stop();
    emit(const AyahAudioState());
  }

  @override
  Future<void> close() {
    _player.dispose();
    return super.close();
  }
}
