import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/hadith/domain/repositories/hadith_library_repository.dart';
import 'package:islami_app_noorify/features/hadith/domain/usecases/track_hadith_reading.dart';
import 'package:islami_app_noorify/features/hadith/presentation/controllers/hadith_reading_tracker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Call {
  _Call(this.hadithIds, this.seconds, this.completed, this.date);
  final List<String> hadithIds;
  final int seconds;
  final bool completed;
  final String date;
}

class _FakeRepository implements HadithLibraryRepository {
  final calls = <_Call>[];
  bool fail = false;

  /// When set, the next report waits for it (an in-flight request).
  Completer<void>? gate;

  @override
  Future<Either<Failure, Unit>> trackReading({
    required List<String> hadithIds,
    required int seconds,
    required bool completed,
    required String date,
  }) async {
    calls.add(_Call(hadithIds, seconds, completed, date));
    await gate?.future;
    return fail ? const Left(NetworkFailure('offline')) : const Right(unit);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeRepository repo;
  late HadithReadingTracker tracker;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repo = _FakeRepository();
    tracker = HadithReadingTracker(
      TrackHadithReading(repo),
      now: () => DateTime(2026, 9, 20, 10),
    );
  });

  void spend(int seconds, {String? on}) {
    for (var i = 0; i < seconds; i++) {
      tracker.tick(on);
    }
  }

  test('20 seconds or less: not a candidate, nothing sent', () {
    spend(15, on: 'a');
    expect(tracker.shouldAskOnLeave, isFalse);
    spend(5, on: 'a'); // exactly 20
    expect(tracker.elapsedSeconds, 20);
    expect(tracker.shouldAskOnLeave, isFalse);
    expect(repo.calls, isEmpty);
  });

  test('more than 20 seconds: it becomes a candidate', () {
    spend(21, on: 'a');
    expect(tracker.shouldAskOnLeave, isTrue);
    expect(tracker.reportCandidates, ['a']);
  });

  test('no candidates when no hadith was ever in focus', () {
    spend(45);
    expect(tracker.elapsedSeconds, 45);
    expect(tracker.shouldAskOnLeave, isFalse);
  });

  test('paused time is not counted', () {
    spend(10, on: 'a');
    tracker.pause();
    spend(60, on: 'a');
    tracker.resume();
    spend(5, on: 'a');
    expect(tracker.elapsedSeconds, 15);
  });

  test('each hadith accrues its own dwell time', () {
    spend(35, on: 'a');
    spend(40, on: 'b');
    expect(tracker.dwellSeconds('a'), 35);
    expect(tracker.dwellSeconds('b'), 40);
    expect(tracker.reportCandidates, unorderedEquals(['a', 'b']));
  });

  test(
    'completing a hadith reports it, marks it completed, and its timer stops',
    () async {
      spend(45, on: 'a');
      expect(await tracker.complete('a'), HadithCompletion.done);

      expect(repo.calls, hasLength(1));
      expect(repo.calls.single.hadithIds, ['a']);
      expect(repo.calls.single.seconds, 45);
      expect(repo.calls.single.completed, isTrue);
      expect(repo.calls.single.date, '2026-09-20');
      expect(tracker.isCompleted('a'), isTrue);
      expect(tracker.shouldAskOnLeave, isFalse); // already reported

      // The timer for 'a' has stopped: further ticks don't add dwell time.
      spend(10, on: 'a');
      expect(tracker.dwellSeconds('a'), 45);

      expect(await tracker.complete('a'), HadithCompletion.alreadyCompleted);
      expect(repo.calls, hasLength(1));
    },
  );

  test('a batch submit reports the sum of each hadith\'s dwell seconds', () async {
    spend(35, on: 'a');
    spend(40, on: 'b');
    expect(
      await tracker.submit(['a', 'b'], completed: true),
      HadithCompletion.done,
    );
    expect(repo.calls, hasLength(1));
    expect(repo.calls.single.hadithIds, ['a', 'b']);
    expect(repo.calls.single.seconds, 75);
    expect(tracker.isCompleted('a'), isTrue);
    expect(tracker.isCompleted('b'), isTrue);
  });

  test(
    'a batch submit drops ids already completed, and sends nothing once none are left',
    () async {
      spend(35, on: 'a');
      spend(40, on: 'b');
      await tracker.complete('a');

      expect(
        await tracker.submit(['a', 'b'], completed: true),
        HadithCompletion.done,
      );
      expect(repo.calls.last.hadithIds, ['b']); // 'a' already done, dropped

      expect(
        await tracker.submit(['a', 'b'], completed: true),
        HadithCompletion.alreadyCompleted,
      );
      expect(repo.calls, hasLength(2)); // no third call
    },
  );

  test('a second tap while the first is in flight sends nothing', () async {
    spend(40, on: 'a');
    final first = tracker.complete('a');
    final second = tracker.complete('a');
    expect(await first, HadithCompletion.done);
    expect(await second, HadithCompletion.alreadyCompleted);
    expect(repo.calls, hasLength(1));
  });

  test('a failed report can be retried with the same time', () async {
    spend(40, on: 'a');
    repo.fail = true;
    expect(await tracker.complete('a'), HadithCompletion.failed);
    expect(tracker.isCompleted('a'), isFalse);
    expect(tracker.reportCandidates, contains('a'));

    repo.fail = false;
    expect(await tracker.complete('a'), HadithCompletion.done);
    expect(repo.calls.last.seconds, 40);
  });

  test('each hadith is reported independently, one at a time', () async {
    spend(35, on: 'a');
    await tracker.complete('a');
    spend(40, on: 'b');
    await tracker.complete('b');
    expect(repo.calls.map((c) => c.hadithIds), [
      ['a'],
      ['b'],
    ]);
    expect(repo.calls.map((c) => c.seconds), [35, 40]);
  });

  test('completed hadiths are remembered across sessions', () async {
    spend(35, on: 'a');
    await tracker.complete('a');

    final next = HadithReadingTracker(TrackHadithReading(repo));
    await next.load();
    expect(next.isCompleted('a'), isTrue);
    expect(await next.complete('a'), HadithCompletion.alreadyCompleted);
    expect(repo.calls, hasLength(1));
  });

  group('timer cleanup', () {
    test('counts each second and never runs two timers', () {
      fakeAsync((async) {
        tracker
          ..start(() => 'a')
          ..start(() => 'a'); // restarting replaces the timer
        async.elapse(const Duration(seconds: 3));
        expect(tracker.elapsedSeconds, 3);
        expect(async.pendingTimers, hasLength(1));
        tracker.dispose();
      });
    });

    test('pause cancels the timer; resume starts one again', () {
      fakeAsync((async) {
        tracker.start(() => 'a');
        async.elapse(const Duration(seconds: 2));

        tracker.pause();
        expect(tracker.isRunning, isFalse);
        expect(async.pendingTimers, isEmpty);
        async.elapse(const Duration(seconds: 60));
        expect(tracker.elapsedSeconds, 2);

        tracker.resume();
        expect(tracker.isRunning, isTrue);
        async.elapse(const Duration(seconds: 3));
        expect(tracker.elapsedSeconds, 5);
        tracker.dispose();
      });
    });

    test('stop cancels the timer for good, even after resume', () {
      fakeAsync((async) {
        tracker.start(() => 'a');
        async.elapse(const Duration(seconds: 2));
        tracker.stop();
        expect(tracker.isRunning, isFalse);
        expect(async.pendingTimers, isEmpty);

        tracker.resume(); // must not bring the timer back
        async.elapse(const Duration(seconds: 30));
        expect(tracker.isRunning, isFalse);
        expect(tracker.elapsedSeconds, 2);
        tracker.dispose();
      });
    });

    test('dispose cancels the timer and clears the visit state', () {
      fakeAsync((async) {
        tracker.start(() => 'a');
        async.elapse(const Duration(seconds: 40));
        expect(tracker.reportCandidates, ['a']);

        tracker.dispose();
        expect(async.pendingTimers, isEmpty);
        expect(tracker.reportCandidates, isEmpty); // dwell cleared
        async.elapse(const Duration(seconds: 60));
        expect(tracker.elapsedSeconds, 40); // nothing kept counting

        tracker.dispose(); // twice is harmless
      });
    });

    test(
      'a report finishing after dispose is safe and still remembered',
      () async {
        spend(40, on: 'a');
        repo.gate = Completer<void>();
        final pending = tracker.complete('a'); // in flight
        tracker.dispose();
        repo.gate!.complete();

        expect(await pending, HadithCompletion.done); // no exception
        expect(repo.calls, hasLength(1));
        expect(tracker.isCompleted('a'), isTrue);
      },
    );
  });
}
