import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami_app_noorify/features/quran/data/services/quran_audio_downloader.dart';
import 'package:islami_app_noorify/features/quran/data/services/quran_audio_handler.dart';
import 'package:islami_app_noorify/features/quran/domain/quran_playlist.dart';
import 'package:islami_app_noorify/features/quran/presentation/screens/quran_audio_player_screen.dart';

import 'quran_playback_test.dart' show TestAudio, TestDownloader;

class _PlaylistDownloader extends TestDownloader {
  @override
  Future<AudioDownloadProgress> surahStatus({
    required int reciterId,
    required int surahNo,
    required int totalAyah,
  }) async => AudioDownloadProgress(totalAyah, totalAyah);
}

QuranPlaylistItem _item(int surahNo, String name, int start, int end) =>
    QuranPlaylistItem(
      surahNo: surahNo,
      surahName: name,
      arabicName: '',
      revelationPlace: 'Meccan',
      startAyah: start,
      endAyah: end,
      totalAyah: end,
    );

void main() {
  testWidgets('playlist plays each Surah and moves on to the next', (
    tester,
  ) async {
    final audio = TestAudio();
    quranAudioHandler = audio;
    addTearDown(audio.completed.close);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => MaterialApp(
          home: QuranAudioPlayerScreen(
            downloader: _PlaylistDownloader(),
            playlist: QuranPlaylist(
              id: 'p1',
              title: 'Morning',
              createdAt: DateTime(2026),
              items: [
                _item(1, 'Al-Fatiha', 1, 2),
                _item(112, 'Al-Ikhlas', 1, 1),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    // Opens playing the first track (Al-Fatiha has no separate Bismillah).
    expect(audio.played, ['1:1']);
    expect(find.text('Ayah 1 of 2'), findsOneWidget);

    audio.completed.add(null);
    await tester.pump(const Duration(milliseconds: 50));
    expect(audio.played, ['1:1', '1:2']);

    // Finishing the last ayah starts the next Surah from its Bismillah.
    audio.completed.add(null);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    expect(audio.played, ['1:1', '1:2', '112:0']);
    expect(find.text('Bismillah'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('quran-player-play')));
    await tester.pump(const Duration(milliseconds: 50));
    expect(audio.pauses, 1);

    // Picking a track from the queue plays it.
    await tester.tap(find.text('Al-Fatiha').last);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    expect(audio.played.last, '1:1');
  });
}
