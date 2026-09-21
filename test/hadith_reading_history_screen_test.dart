import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_read_record.dart';
import 'package:islami_app_noorify/features/hadith/domain/repositories/hadith_library_repository.dart';
import 'package:islami_app_noorify/features/hadith/domain/usecases/get_hadith_read_records.dart';
import 'package:islami_app_noorify/features/hadith/presentation/bloc/hadith_read_records/hadith_read_records_bloc.dart';
import 'package:islami_app_noorify/features/hadith/presentation/screens/hadith_reading_history_screen.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_bloc.dart';

/// Serves [total] records, [limit] per page, and remembers each page asked
/// for.
class _FakeRepository implements HadithLibraryRepository {
  _FakeRepository({required this.total});

  final int total;
  final pages = <int>[];

  @override
  Future<Either<Failure, HadithReadRecordPage>> getReadRecords({
    required int page,
    required int limit,
  }) async {
    pages.add(page);
    final first = (page - 1) * limit;
    final count = (total - first).clamp(0, limit);
    return Right(
      HadithReadRecordPage(
        records: [
          for (var i = first; i < first + count; i++)
            HadithReadRecord(
              id: 'r$i',
              hadithNumber: i,
              subCategoryName: 'Chapter $i',
              subCategoryNameBangla: 'Chapter $i',
              subCategoryNameEnglish: 'Chapter $i',
              lastReadAt: DateTime(2026, 9, 21, 15, 59),
            ),
        ],
        page: page,
        totalPage: (total / limit).ceil(),
        total: total,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pumpScreen(WidgetTester tester, _FakeRepository repo) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, child) => BlocProvider(
        create: (_) => LanguageBloc(),
        child: MaterialApp(
          home: HadithReadingHistoryScreen(
            getRecords: GetHadithReadRecords(repo),
          ),
        ),
      ),
    ),
  );
  await _settle(tester);
}

/// Lets the bloc's async work finish (a spinner never "settles").
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

HadithReadRecordsState _state(WidgetTester tester) =>
    tester.element(find.byType(ListView)).read<HadithReadRecordsBloc>().state;

void main() {
  testWidgets('shows only the list: no Hadith / E-book tabs', (tester) async {
    await _pumpScreen(tester, _FakeRepository(total: 25));

    expect(find.text('E-book'), findsNothing);
    expect(find.text('Chapter 0'), findsOneWidget);
    // Sub-category name and time, as in the design.
    expect(find.text('21 Sep  At 3 : 59 PM'), findsWidgets);
  });

  testWidgets('loads 10 first, then the next 10 as the list is scrolled', (
    tester,
  ) async {
    final repo = _FakeRepository(total: 45);
    await _pumpScreen(tester, repo);

    // Ten per page: page 1 is 10 records. The list is too short to scroll on
    // a tall screen, so it fills itself with page 2 straight away.
    expect(repo.pages.first, 1);
    expect(_state(tester).records.length % 10, 0);
    final afterFirstLoad = _state(tester).records.length;
    expect(afterFirstLoad, greaterThanOrEqualTo(10));

    // Scrolling to the bottom brings in the following page.
    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await _settle(tester);
    expect(_state(tester).records.length, greaterThan(afterFirstLoad));
    expect(repo.pages, [for (var p = 1; p <= repo.pages.length; p++) p]);
  });

  testWidgets('keeps paging after the first 10 until every record is loaded', (
    tester,
  ) async {
    final repo = _FakeRepository(total: 25);
    await _pumpScreen(tester, repo);

    for (var i = 0; i < 6; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -3000));
      await _settle(tester);
    }

    expect(_state(tester).records.length, 25);
    expect(_state(tester).hasMore, isFalse);
    // Pages 1, 2, 3 once each — and nothing asked for beyond the last page.
    expect(repo.pages, [1, 2, 3]);
    expect(find.text('Chapter 24'), findsOneWidget);
  });
}
