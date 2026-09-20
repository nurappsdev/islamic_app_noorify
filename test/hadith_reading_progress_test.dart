import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/hadith/data/models/hadith_reading_progress_model.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_reading_progress.dart';
import 'package:islami_app_noorify/features/hadith/domain/repositories/hadith_library_repository.dart';
import 'package:islami_app_noorify/features/hadith/domain/usecases/get_hadith_reading_progress.dart';
import 'package:islami_app_noorify/features/hadith/presentation/bloc/hadith_reading_progress/hadith_reading_progress_bloc.dart';

class _FakeRepository implements HadithLibraryRepository {
  Either<Failure, HadithReadingProgress> result = const Right(
    HadithReadingProgressModel(
      summary: HadithReadingSummary(
        totalHadiths: 0,
        readHadiths: 0,
        percentage: 0,
        completedGroups: 0,
      ),
      byId: {},
    ),
  );
  int calls = 0;

  @override
  Future<Either<Failure, HadithReadingProgress>> getReadingProgress() async {
    calls++;
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('HadithReadingProgressModel', () {
    final model = HadithReadingProgressModel.fromJson({
      'summary': {
        'totalHadiths': 1947,
        'readHadiths': 16,
        'percentage': 1,
        'completedGroups': 0,
      },
      'data': [
        {
          'id': 'a',
          'bookId': 'b',
          'totalHadiths': 10,
          'readHadiths': 1,
          'percentage': 10,
        },
        {'id': 'over', 'percentage': 140},
        {'id': 'neg', 'percentage': -5},
        {'percentage': 50},
      ],
    });

    test('reads the summary and matches categories by id', () {
      expect(model.summary.percentage, 1);
      expect(model.summary.readHadiths, 16);
      expect(model.forCategory('a')!.percentage, 10);
      expect(model.forCategory('a')!.fraction, 0.1);
      expect(model.forCategory('missing'), isNull);
    });

    test('clamps percentage to 0..100 and skips entries without an id', () {
      expect(model.forCategory('over')!.percentage, 100);
      expect(model.forCategory('neg')!.percentage, 0);
      expect(model.byId.length, 3);
    });

    test('tolerates an empty payload', () {
      final empty = HadithReadingProgressModel.fromJson(const {});
      expect(empty.byId, isEmpty);
      expect(empty.summary.percentage, 0);
    });
  });

  group('HadithReadingProgressBloc', () {
    late _FakeRepository repo;
    late HadithReadingProgressBloc bloc;

    setUp(() {
      repo = _FakeRepository();
      bloc = HadithReadingProgressBloc(GetHadithReadingProgress(repo));
    });
    tearDown(() => bloc.close());

    test('load: loading, then success', () async {
      final statuses = <HadithReadingProgressStatus>[];
      final sub = bloc.stream.listen((s) => statuses.add(s.status));
      bloc.add(const LoadHadithReadingProgress());
      await bloc.stream.firstWhere((s) => !s.isLoading);
      await sub.cancel();
      expect(statuses, [
        HadithReadingProgressStatus.loading,
        HadithReadingProgressStatus.success,
      ]);
    });

    test('failure: no progress, so every ring shows 0%', () async {
      repo.result = const Left(NetworkFailure('offline'));
      bloc.add(const LoadHadithReadingProgress());
      final state = await bloc.stream.firstWhere((s) => !s.isLoading);
      expect(state.status, HadithReadingProgressStatus.failure);
      expect(state.forCategory('a'), isNull);
    });

    test('refresh keeps the last progress when the request fails', () async {
      bloc.add(const LoadHadithReadingProgress());
      await bloc.stream.firstWhere((s) => !s.isLoading);
      repo.result = const Left(NetworkFailure('offline'));
      bloc.add(const RefreshHadithReadingProgress());
      final state = await bloc.stream.firstWhere(
        (s) => s.status == HadithReadingProgressStatus.failure,
      );
      expect(state.progress, isNotNull);
      expect(repo.calls, 2);
    });
  });
}
