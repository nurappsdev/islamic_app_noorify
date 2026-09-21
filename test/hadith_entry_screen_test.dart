import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami_app_noorify/features/hadith/data/hadith_intro_store.dart';
import 'package:islami_app_noorify/features/hadith/presentation/screens/hadith_entry_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A store whose storage fails, to check the screen doesn't get stuck.
class _BrokenStore extends HadithIntroStore {
  const _BrokenStore();

  @override
  Future<bool> takeFirstVisit() => throw StateError('storage unavailable');
}

Widget _entry({HadithIntroStore store = const HadithIntroStore()}) =>
    MaterialApp(
      home: HadithEntryScreen(
        store: store,
        // The real screens need the network and Hive; stand-ins are enough to
        // see which one is chosen.
        introBuilder: (_) => const Text('INTRO'),
        libraryBuilder: (_) => const Text('LIBRARY'),
      ),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('HadithIntroStore', () {
    test('takeFirstVisit is true once, then false forever', () async {
      const store = HadithIntroStore();
      expect(await store.hasSeen(), isFalse);
      expect(await store.takeFirstVisit(), isTrue);
      expect(await store.hasSeen(), isTrue);
      expect(await store.takeFirstVisit(), isFalse);
      expect(await store.takeFirstVisit(), isFalse);
    });

    test('remembers across store instances (a restart)', () async {
      expect(await const HadithIntroStore().takeFirstVisit(), isTrue);
      expect(await const HadithIntroStore().takeFirstVisit(), isFalse);
    });
  });

  group('HadithEntryScreen', () {
    testWidgets('the first time shows the intro, not the library', (
      tester,
    ) async {
      await tester.pumpWidget(_entry());
      await tester.pumpAndSettle();

      expect(find.text('INTRO'), findsOneWidget);
      expect(find.text('LIBRARY'), findsNothing);
    });

    testWidgets('every time after that goes straight to the library', (
      tester,
    ) async {
      // First open: the intro.
      await tester.pumpWidget(_entry());
      await tester.pumpAndSettle();
      expect(find.text('INTRO'), findsOneWidget);

      // Tapping Hadith on Home again, and again: the library each time.
      for (var i = 0; i < 3; i++) {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(_entry());
        await tester.pumpAndSettle();
        expect(find.text('LIBRARY'), findsOneWidget);
        expect(find.text('INTRO'), findsNothing);
      }
    });

    testWidgets('the intro counts as seen even if the user backs out', (
      tester,
    ) async {
      await tester.pumpWidget(_entry());
      await tester.pumpAndSettle();
      // Leave without pressing anything on the intro, then reopen.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(_entry());
      await tester.pumpAndSettle();

      expect(find.text('LIBRARY'), findsOneWidget);
    });

    testWidgets('a broken store goes to the library instead of hanging', (
      tester,
    ) async {
      await tester.pumpWidget(_entry(store: const _BrokenStore()));
      await tester.pumpAndSettle();

      expect(find.text('LIBRARY'), findsOneWidget);
    });
  });
}
