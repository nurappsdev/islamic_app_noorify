import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_category.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_category_page.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_library_book.dart';
import 'package:islami_app_noorify/features/hadith/domain/repositories/hadith_library_repository.dart';
import 'package:islami_app_noorify/features/hadith/domain/usecases/update_hadith_plan.dart';
import 'package:islami_app_noorify/features/hadith/presentation/bloc/hadith_edit_plan/hadith_edit_plan_bloc.dart';
import 'package:islami_app_noorify/features/hadith/presentation/screens/hadith_edit_plan_screen.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_bloc.dart';

const _catA = HadithCategory(
  id: 'cat-a',
  bookId: 'book-1',
  name: 'Category A',
  nameBangla: 'Category A',
  nameArabic: '',
  sectionNumber: 1,
  displayOrder: 1,
  totalHadiths: 12,
  totalSubCategories: 0,
);

const _catB = HadithCategory(
  id: 'cat-b',
  bookId: 'book-1',
  name: 'Category B',
  nameBangla: 'Category B',
  nameArabic: '',
  sectionNumber: 2,
  displayOrder: 2,
  totalHadiths: 8,
  totalSubCategories: 0,
);

const _catC = HadithCategory(
  id: 'cat-c',
  bookId: 'book-2',
  name: 'Category C',
  nameBangla: 'Category C',
  nameArabic: '',
  sectionNumber: 1,
  displayOrder: 1,
  totalHadiths: 5,
  totalSubCategories: 0,
);

const _bookOne = HadithLibraryBook(
  id: 'book-1',
  titleEn: 'Book One',
  titleBn: 'Book One',
  titleAr: '',
  authorEn: '',
  authorBn: '',
  totalHadiths: 40,
  totalCategories: 2,
  totalSubCategories: 0,
  displayOrder: 1,
);

const _bookTwo = HadithLibraryBook(
  id: 'book-2',
  titleEn: 'Book Two',
  titleBn: 'Book Two',
  titleAr: '',
  authorEn: '',
  authorBn: '',
  totalHadiths: 20,
  totalCategories: 1,
  totalSubCategories: 0,
  displayOrder: 2,
);

const _args = HadithEditPlanArgs(
  planId: 'p1',
  name: 'My plan',
  bookId: 'book-1',
  bookTitle: 'Book One',
  categoryIds: ['cat-a'],
  targetDays: 20,
);

/// Serves two books and book-1's categories (A and B), and records / answers
/// `updatePlan`.
class _FakeRepository implements HadithLibraryRepository {
  _FakeRepository({this.updateResult});

  /// What saving answers; success unless a test sets a failure.
  Either<Failure, Unit>? updateResult;
  final updates =
      <
        ({
          String id,
          String? name,
          int? targetDays,
          String? bookId,
          List<String>? categoryIds,
          List<String>? subCategoryIds,
        })
      >[];

  /// When set, saving waits for it, i.e. the request stays in flight.
  Completer<void>? gate;

  @override
  Future<Either<Failure, List<HadithLibraryBook>>> getBooks() async =>
      const Right([_bookOne, _bookTwo]);

  @override
  Future<Either<Failure, HadithCategoryPage>> getCategories(
    String bookId, {
    required int page,
    required int limit,
    String? searchTerm,
  }) async => Right(
    HadithCategoryPage(
      categories: bookId == 'book-1'
          ? const [_catA, _catB]
          : bookId == 'book-2'
          ? const [_catC]
          : const [],
      page: 1,
      totalPage: 1,
      total: 2,
    ),
  );

  @override
  Future<Either<Failure, Unit>> updatePlan(
    String id, {
    String? name,
    int? targetDays,
    String? status,
    String? bookId,
    List<String>? categoryIds,
    List<String>? subCategoryIds,
  }) async {
    updates.add((
      id: id,
      name: name,
      targetDays: targetDays,
      bookId: bookId,
      categoryIds: categoryIds,
      subCategoryIds: subCategoryIds,
    ));
    await gate?.future;
    return updateResult ?? const Right(unit);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('HadithEditPlanBloc', () {
    test('success: submitting, then success', () async {
      final repo = _FakeRepository();
      final bloc = HadithEditPlanBloc(UpdateHadithPlan(repo));
      addTearDown(bloc.close);

      final states = <HadithEditPlanStatus>[];
      final sub = bloc.stream.listen((s) => states.add(s.status));
      bloc.add(
        const SubmitHadithPlanEdit(
          id: 'p1',
          name: 'Renamed',
          bookId: 'book-1',
          categoryIds: ['cat-a'],
          subCategoryIds: [],
          targetDays: 15,
        ),
      );
      await bloc.stream.firstWhere((s) => !s.isSubmitting);
      await sub.cancel();

      expect(states, [
        HadithEditPlanStatus.submitting,
        HadithEditPlanStatus.success,
      ]);
      // Records compare List fields by identity, not by contents — check
      // each field, so the list fields get proper deep equality.
      final sent = repo.updates.single;
      expect(sent.id, 'p1');
      expect(sent.name, 'Renamed');
      expect(sent.targetDays, 15);
      expect(sent.bookId, 'book-1');
      expect(sent.categoryIds, ['cat-a']);
      expect(sent.subCategoryIds, <String>[]);
    });

    test('failure keeps the API message', () async {
      final repo = _FakeRepository(
        updateResult: const Left(
          ServerFailure(
            'A plan with this name already exists',
            statusCode: 409,
          ),
        ),
      );
      final bloc = HadithEditPlanBloc(UpdateHadithPlan(repo));
      addTearDown(bloc.close);

      bloc.add(
        const SubmitHadithPlanEdit(
          id: 'p1',
          name: 'Renamed',
          bookId: 'book-1',
          categoryIds: ['cat-a'],
          subCategoryIds: [],
        ),
      );
      final done = await bloc.stream.firstWhere((s) => !s.isSubmitting);

      expect(done.status, HadithEditPlanStatus.failure);
      expect(done.failure!.message, 'A plan with this name already exists');
    });

    test('a second tap while saving does not send twice', () async {
      final repo = _FakeRepository()..gate = Completer<void>();
      final bloc = HadithEditPlanBloc(UpdateHadithPlan(repo));
      addTearDown(bloc.close);

      const event = SubmitHadithPlanEdit(
        id: 'p1',
        name: 'Renamed',
        bookId: 'book-1',
        categoryIds: ['cat-a'],
        subCategoryIds: [],
      );
      bloc.add(event);
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.isSubmitting, isTrue);
      bloc.add(event);
      await Future<void>.delayed(Duration.zero);

      expect(repo.updates, hasLength(1));
      repo.gate!.complete();
      await bloc.stream.firstWhere((s) => !s.isSubmitting);
      expect(repo.updates, hasLength(1));
    });
  });

  group('HadithEditPlanScreen', () {
    bool? popped;

    /// A host that opens the edit screen and keeps what it popped with.
    Future<void> pumpHost(WidgetTester tester, _FakeRepository repo) async {
      popped = null;
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
              home: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () async {
                      popped = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) =>
                              HadithEditPlanScreen(args: _args, repository: repo),
                        ),
                      );
                    },
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('opens pre-filled with the plan\'s name, days and book', (
      tester,
    ) async {
      await pumpHost(tester, _FakeRepository());

      final name = tester.widget<TextField>(
        find.byKey(const Key('edit-plan-name-field')),
      );
      final days = tester.widget<TextFormField>(
        find.byKey(const Key('edit-target-days-field')),
      );
      expect(name.controller!.text, 'My plan');
      expect(days.controller!.text, '20');
      expect(find.text('Book One'), findsOneWidget);
    });

    testWidgets('picking a different book clears the categories', (
      tester,
    ) async {
      final repo = _FakeRepository();
      await pumpHost(tester, repo);
      expect(find.text('Category A'), findsOneWidget);

      await tester.tap(find.text('Book One'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Book Two'));
      await tester.pumpAndSettle();

      expect(find.text('Book Two'), findsOneWidget);
      // Category A belonged to Book One; it doesn't carry over.
      expect(find.text('Category A'), findsNothing);

      await tester.tap(find.text('Save'));
      await tester.pump();
      // No category left on the new book: the same guard as an empty list.
      expect(repo.updates, isEmpty);
    });

    testWidgets('Save sends the newly picked book and its category', (
      tester,
    ) async {
      final repo = _FakeRepository();
      await pumpHost(tester, repo);

      await tester.tap(find.text('Book One'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Book Two'));
      await tester.pumpAndSettle();

      // Add opens the picker scoped to the new book, so only Book Two's own
      // category shows.
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Category C'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final sent = repo.updates.single;
      expect(sent.bookId, 'book-2');
      expect(sent.categoryIds, ['cat-c']);
      expect(popped, isTrue);
    });

    testWidgets('resolves and shows the already-selected category', (
      tester,
    ) async {
      await pumpHost(tester, _FakeRepository());

      expect(find.text('Category A'), findsOneWidget);
      expect(find.text('12 Hadith'), findsOneWidget);
    });

    testWidgets('the remove button drops a category', (tester) async {
      final repo = _FakeRepository();
      await pumpHost(tester, repo);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Category A'), findsNothing);

      await tester.tap(find.text('Save'));
      await tester.pump();
      // Nothing left: the same guard as Create Plan's "no category" message.
      expect(repo.updates, isEmpty);
    });

    testWidgets('Add picks another category from the same book', (
      tester,
    ) async {
      final repo = _FakeRepository();
      await pumpHost(tester, repo);

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Category B'));
      await tester.pumpAndSettle();

      expect(find.text('Category A'), findsOneWidget);
      expect(find.text('Category B'), findsOneWidget);

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final sent = repo.updates.single;
      expect(sent.id, 'p1');
      expect(sent.categoryIds, ['cat-a', 'cat-b']);
      expect(sent.subCategoryIds, <String>[]);
      expect(popped, isTrue);
    });

    testWidgets('Save sends the edited name and days', (tester) async {
      final repo = _FakeRepository();
      await pumpHost(tester, repo);

      await tester.enterText(
        find.byKey(const Key('edit-plan-name-field')),
        'Renamed plan',
      );
      await tester.enterText(
        find.byKey(const Key('edit-target-days-field')),
        '45',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final sent = repo.updates.single;
      expect(sent.name, 'Renamed plan');
      expect(sent.targetDays, 45);
      expect(popped, isTrue);
    });

    testWidgets('the API refusing (name taken) shows its message and stays', (
      tester,
    ) async {
      final repo = _FakeRepository(
        updateResult: const Left(
          ServerFailure(
            'A plan with this name already exists',
            statusCode: 409,
          ),
        ),
      );
      await pumpHost(tester, repo);

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(repo.updates, hasLength(1));
      expect(find.text('A plan with this name already exists'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(popped, isNull);
    });
  });
}
