import 'package:flutter_test/flutter_test.dart';
import 'package:tuhfatul_muslim/features/quran/data/services/quran_audio_handler.dart';
import 'package:tuhfatul_muslim/features/quran/domain/quran_playlist.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/bloc/quran_playlist_playback/quran_playlist_playback_cubit.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/bloc/surah_playback/surah_playback_bloc.dart';

import 'quran_playback_test.dart' show TestAudio, TestDownloader, settle;

QuranPlaylistItem _item(int surahNo, int start, int end) => QuranPlaylistItem(
  surahNo: surahNo,
  surahName: 'Surah $surahNo',
  arabicName: '',
  revelationPlace: 'Meccan',
  startAyah: start,
  endAyah: end,
  totalAyah: end,
);

/// Al-Fatiha 1-2, Al-Ikhlas 1-1, An-Nas 1-1.
final _items = [_item(1, 1, 2), _item(112, 1, 1), _item(114, 1, 1)];

void main() {
  late TestAudio audio;
  late QuranPlaylistPlaybackCubit playlist;

  // No widget tree anywhere below: like a phone with its screen off, nothing
  // is ever built or drawn. Only audio events drive playback.
  setUp(() async {
    audio = TestAudio();
    playlist = QuranPlaylistPlaybackCubit(
      items: _items,
      recitationId: () => 7,
      downloader: TestDownloader(),
      audio: audio,
    );
    await settle();
  });

  tearDown(() async {
    await playlist.close();
    await audio.completed.close();
    await audio.remote.close();
  });

  Future<void> finishClip() async {
    audio.completed.add(null);
    await settle();
  }

  test('plays every Surah in order with nothing on screen', () async {
    expect(audio.played, ['1:1']);
    expect(audio.queueControls, isTrue, reason: 'Previous/Next shown');

    await finishClip(); // 1:1 -> 1:2
    await finishClip(); // end of Al-Fatiha -> Al-Ikhlas from its Bismillah
    await finishClip(); // Bismillah -> 112:1
    await finishClip(); // end of Al-Ikhlas -> An-Nas
    await finishClip();
    expect(audio.played, ['1:1', '1:2', '112:0', '112:1', '114:0', '114:1']);
    expect(playlist.state.index, 2);
    expect(audio.stops, 0, reason: 'the session never restarts in between');

    // The last Surah ends: the playlist is done and the session ends.
    await finishClip();
    expect(playlist.state.finished, isTrue);
    expect(audio.stops, 1);
    expect(audio.queueControls, isFalse);
    expect(audio.played, hasLength(6), reason: 'nothing plays after the end');
  });

  test('Next and Previous from the notification change Surah', () async {
    audio.remote.add(QuranAudioCommand.next);
    await settle();
    expect(playlist.state.index, 1);
    expect(audio.played.last, '112:0');

    audio.remote.add(QuranAudioCommand.next);
    await settle();
    expect(playlist.state.index, 2);
    // Already the last: Next does nothing.
    audio.remote.add(QuranAudioCommand.next);
    await settle();
    expect(playlist.state.index, 2);

    audio.remote.add(QuranAudioCommand.previous);
    await settle();
    expect(playlist.state.index, 1);
    audio.remote.add(QuranAudioCommand.previous);
    await settle();
    expect(playlist.state.index, 0);
    // On the first: Previous starts it again.
    final before = audio.played.length;
    audio.remote.add(QuranAudioCommand.previous);
    await settle();
    expect(playlist.state.index, 0);
    expect(audio.played.length, before + 1);
    expect(audio.played.last, '1:1');
    expect(audio.stops, 0);
  });

  test('a pause from the lock screen holds; play resumes and goes on', () async {
    final track = playlist.state.track;
    audio.remote.add(QuranAudioCommand.pause);
    await settle();
    expect(track.state.isPlaying, isFalse);

    // Paused: a stray completion does not move on.
    await finishClip();
    expect(audio.played, ['1:1']);

    audio.remote.add(QuranAudioCommand.play);
    await settle();
    expect(track.state.isPlaying, isTrue);
    await finishClip();
    expect(audio.played, ['1:1', '1:2']);
  });

  test('picking a track in the app keeps the session', () async {
    await playlist.select(2);
    await settle();
    expect(audio.played.last, '114:0');
    expect(audio.stops, 0);
  });

  test('leaving the player ends the playlist and its controls', () async {
    await playlist.close();
    expect(audio.stops, 1);
    expect(audio.queueControls, isFalse);
  });

  test('the single-Surah player follows the notification too', () async {
    final reader = SurahPlaybackBloc(
      audio: audio,
      downloader: TestDownloader(),
    );
    addTearDown(reader.close);
    await playlist.close();
    reader.add(const PlaySurah(surahNo: 1, totalAyah: 7, recitationId: 7));
    await settle();
    expect(reader.state.isPlaying, isTrue);

    audio.remote.add(QuranAudioCommand.pause);
    await settle();
    expect(reader.state.isPlaying, isFalse);
    audio.remote.add(QuranAudioCommand.play);
    await settle();
    expect(reader.state.isPlaying, isTrue);

    // Stop from the notification: stays stopped.
    audio.remote.add(QuranAudioCommand.stop);
    await settle();
    expect(reader.state.isPlaying, isFalse);
  });
}
