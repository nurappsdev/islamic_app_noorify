import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/hadith/domain/repositories/hadith_library_repository.dart';
import 'package:islami_app_noorify/features/hadith/domain/usecases/track_hadith_reading.dart';
import 'package:islami_app_noorify/features/hadith/presentation/controllers/hadith_reading_tracker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Call {
  _Call(this.hadithId, this.seconds, this.completed, this.date);
  final String hadithId;
  final int seconds;
  final bool completed;
  final String date;
}

class _FakeRepository implements HadithLibraryRepository {
  final calls = <_Call>[];
  bool fail = false;

  @override
  Future<Either<Failure, Unit>> trackReading({
    required String hadithId,
    required int seconds,
    required bool completed,
    required String date,
  }) async {
    calls.add(_Call(hadithId, seconds, completed, date));
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

  test('30 seconds or less: no dialog, nothing sent', () {
    spend(20, on: 'a');
    expect(tracker.shouldAskOnLeave, isFalse);
    spend(10, on: 'a'); // exactly 30
    expect(tracker.elapsedSeconds, 30);
    expect(tracker.shouldAskOnLeave, isFalse);
    expect(repo.calls, isEmpty);
  });

  test('more than 30 seconds: the dialog is asked', () {
    spend(31, on: 'a');
    expect(tracker.shouldAskOnLeave, isTrue);
    expect(tracker.reportCandidate, 'a');
  });

  test('no dialog when no hadith was ever in focus', () {
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

  test('attributes the time to the hadith in focus the longest', () {
    spend(10, on: 'a');
    spend(25, on: 'b');
    spend(5, on: 'a');
    expect(tracker.elapsedSeconds, 40);
    expect(tracker.reportCandidate, 'b');
  });

  test('Yes sends the total time with completed true, once', () async {
    spend(45, on: 'a');
    expect(await tracker.complete('a'), HadithCompletion.done);

    expect(repo.calls, hasLength(1));
    expect(repo.calls.single.hadithId, 'a');
    expect(repo.calls.single.seconds, 45);
    expect(repo.calls.single.completed, isTrue);
    expect(repo.calls.single.date, '2026-09-20');
    expect(tracker.isCompleted('a'), isTrue);
    expect(tracker.shouldAskOnLeave, isFalse); // already reported

    expect(await tracker.complete('a'), HadithCompletion.alreadyCompleted);
    expect(repo.calls, hasLength(1));
  });

  test('No sends the same time with completed false', () async {
    spend(70, on: 'a');
    expect(await tracker.submit('a', completed: false), HadithCompletion.done);
    expect(repo.calls.single.seconds, 70);
    expect(repo.calls.single.completed, isFalse);
    expect(tracker.isCompleted('a'), isFalse);
    expect(tracker.shouldAskOnLeave, isFalse);
  });

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
    expect(tracker.shouldAskOnLeave, isTrue);

    repo.fail = false;
    expect(await tracker.complete('a'), HadithCompletion.done);
    expect(repo.calls.last.seconds, 40);
  });

  test('a later report sends only the time since the last one', () async {
    spend(12, on: 'a');
    await tracker.complete('a'); // Complete button after 12 s
    spend(20, on: 'b');
    await tracker.complete('b');
    expect(repo.calls.map((c) => c.seconds), [12, 20]);
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
}
