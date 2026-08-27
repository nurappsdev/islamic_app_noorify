import 'package:audioplayers/audioplayers.dart';
import 'package:bloc/bloc.dart';

import 'package:islami_app_noorify/features/quran/data/services/quran_audio_downloader.dart';
import 'package:islami_app_noorify/features/quran/data/services/quran_reader_service.dart';

import 'ayah_audio_event.dart';
import 'ayah_audio_state.dart';

export 'ayah_audio_event.dart';
export 'ayah_audio_state.dart';

/// One shared instance per surah screen so only one ayah plays at a time.
class AyahAudioBloc extends Bloc<AyahAudioEvent, AyahAudioState> {
  AyahAudioBloc({QuranReaderService? readerService, this.downloader})
    : _readerService = readerService ?? QuranComReaderService(),
      super(const AyahAudioState()) {
    _player.onPlayerComplete.listen((_) => add(const StopAyahAudio()));
    on<PlayAyahAudio>(_onPlay);
    on<StopAyahAudio>(_onStop);
  }

  final QuranReaderService _readerService;

  /// When set, a downloaded local file is preferred over streaming.
  final QuranAudioDownloader? downloader;
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
      final localPath = await downloader?.localPathFor(
        reciterId: event.recitationId,
        verseKey: event.verseKey,
      );
      if (state.playingVerseKey != event.verseKey) return;
      if (localPath != null) {
        await _player.play(DeviceFileSource(localPath));
        emit(AyahAudioState(playingVerseKey: event.verseKey));
        return;
      }
      final url = await _readerService.loadAyahAudioUrl(
        event.recitationId,
        event.verseKey,
      );
      if (state.playingVerseKey != event.verseKey) return;
      await _player.play(UrlSource(url));
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
