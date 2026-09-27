import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami_app_noorify/features/quran/data/services/quran_audio_handler.dart';
import 'package:islami_app_noorify/features/quran/data/services/quran_audio_downloader.dart';
import 'package:islami_app_noorify/features/quran/presentation/bloc/surah_playback/surah_playback_bloc.dart';

class TestAudio extends BaseAudioHandler implements QuranAudioHandler {
  final completed = StreamController<void>.broadcast();
  final played = <String>[];
  int resumes = 0, pauses = 0;
  @override
  Stream<void> get onCompleted => completed.stream;
  @override
  Stream<Duration> get positionStream => const Stream.empty();
  @override
  Duration? get duration => const Duration(seconds: 10);
  @override
  Future<void> playFile(String path, {required MediaItem item}) async {
    played.add(item.id);
    mediaItem.add(item);
    playbackState.add(
      PlaybackState(playing: true, processingState: AudioProcessingState.ready),
    );
  }

  @override
  Future<void> play() async {
    resumes++;
  }

  @override
  Future<void> pause() async {
    pauses++;
  }

  @override
  Future<void> stopCurrent() async {
    playbackState.add(
      PlaybackState(processingState: AudioProcessingState.idle),
    );
  }

  @override
  Future<void> stop() async {}
}

class TestDownloader extends QuranAudioDownloader {
  bool complete = true;
  @override
  Future<bool> isSurahComplete({
    required int reciterId,
    required int surahNo,
    required int totalAyah,
  }) async => complete;
  @override
  Future<String?> localPathFor({
    required int reciterId,
    required String verseKey,
  }) async => '/test/$verseKey.mp3';
  @override
  Future<String?> localBismillahPath(int reciterId) async =>
      '/test/bismillah.mp3';
}

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));
void main() {
  test('play, pause, and resume reuse the same audio clip', () async {
    final audio = TestAudio();
    final bloc = SurahPlaybackBloc(audio: audio, downloader: TestDownloader());
    addTearDown(() async {
      await bloc.close();
      await audio.completed.close();
    });
    const play = PlaySurah(surahNo: 1, totalAyah: 7, recitationId: 7);
    bloc.add(play);
    await settle();
    expect(audio.played, ['1:1']);
    expect(bloc.state.isPlaying, true);
    bloc.add(const PauseSurah());
    await settle();
    expect(bloc.state.isPlaying, false);
    expect(audio.pauses, 1);
    bloc.add(play);
    await settle();
    expect(audio.played, ['1:1']);
    expect(audio.resumes, 1);
    expect(bloc.state.isPlaying, true);
  });
  test(
    'completion advances the active ayah and stops at Para boundary',
    () async {
      final audio = TestAudio();
      final bloc = SurahPlaybackBloc(
        audio: audio,
        downloader: TestDownloader(),
        startAyah: 252,
        endAyah: 253,
      );
      addTearDown(() async {
        await bloc.close();
        await audio.completed.close();
      });
      bloc.add(const SetActiveAyah(252));
      await settle();
      bloc.add(const PlaySurah(surahNo: 2, totalAyah: 286, recitationId: 7));
      await settle();
      audio.completed.add(null);
      await settle();
      expect(bloc.state.currentAyahNo, 253);
      audio.completed.add(null);
      await settle();
      expect(bloc.state.isPlaying, false);
      expect(audio.played, ['2:252', '2:253']);
    },
  );
  test('missing audio still triggers the existing download gate', () async {
    final audio = TestAudio();
    final downloader = TestDownloader()..complete = false;
    final bloc = SurahPlaybackBloc(audio: audio, downloader: downloader);
    addTearDown(() async {
      await bloc.close();
      await audio.completed.close();
    });
    final seen = <bool>[];
    final sub = bloc.stream.listen((s) => seen.add(s.needsDownload));
    bloc.add(const PlaySurah(surahNo: 1, totalAyah: 7, recitationId: 7));
    await settle();
    expect(seen, contains(true));
    expect(audio.played, isEmpty);
    await sub.cancel();
  });
}
