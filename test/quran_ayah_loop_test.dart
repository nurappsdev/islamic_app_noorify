import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuhfatul_muslim/features/quran/domain/arabic_font.dart';
import 'package:tuhfatul_muslim/features/quran/domain/quran_ayah.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/bloc/surah_playback/surah_playback_bloc.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/widgets/quran_reading_text.dart';

import 'quran_playback_test.dart' show TestAudio, TestDownloader, settle;

void main() {
  late TestAudio audio;
  late SurahPlaybackBloc bloc;

  setUp(() {
    audio = TestAudio();
    bloc = SurahPlaybackBloc(audio: audio, downloader: TestDownloader());
  });

  tearDown(() async {
    await bloc.close();
    await audio.completed.close();
    await audio.remote.close();
  });

  Future<void> finishClip() async {
    audio.completed.add(null);
    await settle();
  }

  // Al-Fatiha: no separate Bismillah clip, so ayah 1 plays first.
  const fatiha = PlaySurah(surahNo: 1, totalAyah: 7, recitationId: 7);

  test('a looped ayah plays its count, then the Surah goes on', () async {
    bloc.add(const SetAyahRepeat(2, 3));
    bloc.add(fatiha);
    await settle();
    for (var i = 0; i < 4; i++) {
      await finishClip();
    }
    expect(audio.played, ['1:1', '1:2', '1:2', '1:2', '1:3']);
    expect(bloc.state.repeatCountFor(2), 3, reason: 'kept for next time');
    expect(bloc.state.isPlaying, isTrue);
  });

  test('a loop set on the ayah playing applies at once', () async {
    bloc.add(fatiha);
    await settle();
    bloc.add(const SetAyahRepeat(1, 2));
    await settle();
    await finishClip();
    await finishClip();
    expect(audio.played, ['1:1', '1:1', '1:2']);

    // Turned off mid-loop: no more plays of it.
    bloc.add(const SetAyahRepeat(2, 5));
    await settle();
    await finishClip(); // 1:2 again (5 plays from now)
    bloc.add(const SetAyahRepeat(2, 1));
    await settle();
    await finishClip();
    expect(audio.played, ['1:1', '1:1', '1:2', '1:2', '1:3']);
  });

  test('play from a chosen ayah jumps there and continues', () async {
    bloc.add(fatiha);
    await settle();
    bloc.add(
      const PlaySurah(surahNo: 1, totalAyah: 7, recitationId: 7, fromAyah: 5),
    );
    await settle();
    expect(audio.played.last, '1:5');
    expect(bloc.state.currentAyahNo, 5);
    await finishClip();
    expect(audio.played.last, '1:6');
  });

  test('choosing ayah 1 plays it, not the Bismillah before it', () async {
    bloc.add(
      const PlaySurah(surahNo: 2, totalAyah: 286, recitationId: 7, fromAyah: 1),
    );
    await settle();
    expect(audio.played, ['2:1']);
  });

  test('the chosen ayah loops too', () async {
    bloc.add(const SetAyahRepeat(4, 2));
    bloc.add(
      const PlaySurah(surahNo: 1, totalAyah: 7, recitationId: 7, fromAyah: 4),
    );
    await settle();
    await finishClip();
    await finishClip();
    expect(audio.played, ['1:4', '1:4', '1:5']);
  });

  test('a Surah repeat chosen while playing is honoured', () async {
    bloc.add(const PlaySurah(surahNo: 1, totalAyah: 2, recitationId: 7));
    await settle();
    bloc.add(const SetRepeatCount(2));
    await settle();
    await finishClip(); // 1:2
    await finishClip(); // end of the first time round: again
    expect(audio.played, ['1:1', '1:2', '1:1']);
  });

  test('loop steps: 1, 2, 3, 5, then off', () {
    expect([1, 2, 3, 5].map(nextAyahRepeatCount), [2, 3, 5, 1]);
  });

  group('tapping an ayah', () {
    Future<({List<int> taps, List<int> holds})> pump(
      WidgetTester tester,
    ) async {
      final taps = <int>[], holds = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                QuranReadingText(
                  ayahs: [
                    for (var n = 1; n <= 2; n++)
                      QuranAyah(
                        surahNumber: 2,
                        ayahNumber: n,
                        verseKey: '2:$n',
                        ayahIndex: n + 7,
                        paraNumber: 1,
                        pageNumber: 2,
                        textArabic:
                            'ذَٰلِكَ الْكِتَابُ لَا رَيْبَ فِيهِ هُدًى لِلْمُتَّقِينَ',
                      ),
                  ],
                  active: 0,
                  scale: 1,
                  font: arabicFontById('noorehuda'),
                  onTap: (ayah) => taps.add(ayah.ayahNumber),
                  onHold: (ayah) => holds.add(ayah.ayahNumber),
                ),
                const SizedBox(height: 2000),
              ],
            ),
          ),
        ),
      );
      return (taps: taps, holds: holds);
    }

    Finder marker(int n) => find.byKey(ValueKey('ayah-marker-2:$n'));

    testWidgets('a tap selects it; a hold opens it, not both', (tester) async {
      final seen = await pump(tester);
      await tester.tap(marker(2));
      await tester.pump(kAyahHoldDuration);
      expect(seen.taps, [2]);
      expect(seen.holds, isEmpty);

      // Held for the reader's full hold time, then lifted.
      final hold = await tester.startGesture(tester.getCenter(marker(1)));
      await tester.pump(kAyahHoldDuration + const Duration(milliseconds: 50));
      await hold.up();
      await tester.pump();
      expect(seen.holds, [1]);
      expect(seen.taps, [2], reason: 'a hold is no tap');
    });

    testWidgets('a scroll starting on it is neither', (tester) async {
      final seen = await pump(tester);
      await tester.drag(marker(1), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(seen.taps, isEmpty);
      expect(seen.holds, isEmpty);
    });
  });
}
